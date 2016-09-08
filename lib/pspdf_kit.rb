module PSPDFKit
  extend self

  attr_reader :base_url

  def configure(base_url:, auth_token:, jwt_key:)
    @base_url = base_url
    @client = RestClient::Resource.new(
      base_url,
      verify_ssl: OpenSSL::SSL::VERIFY_NONE,
      headers: {"Authorization" => "Token token=#{auth_token}"}
    )
    @jwt_key = jwt_key
  end

  def upload_document(path)
    response = client["api/document"].post(
      File.read(path),
      content_type: "application/pdf"
    )
    doc = JSON.parse(response.body)

    { id: dig(doc, "data", "document_id"), title: dig(doc, "data", "document_properties", "title") }
  end

  def cover_image_url(id, dim, size)
    raise(ArgumentError, "Invalid dimension") unless %i(width height).include?(dim)
    raise(ArgumentError, "Invalid size") unless size.to_i.between?(1,1024)

    params = {}
    params[:jwt] = jwt_sign({document_id: id, context: "cover"})
    params[dim] = size

    URI.parse(@base_url).tap do |u|
      u.path = "/d/#{id}/cover"
      u.query = {
        "jwt" => jwt_sign({document_id: id, context: "cover"}),
        dim => size
      }.to_query
    end.to_s
  end

  def document_change_permissions(id, add_users: [], remove_users: [])
    client["api/change_users"].post(
      { document_id: id, changes: {add_users: add_users.map(&:to_s), remove_users: remove_users.map(&:to_s)}}.to_json,
      content_type: :json,
      accept: :json
    )
  end

  def jwt_sign(payload)
    JWT.encode(
      payload.merge(exp: Time.now.to_i + 60*60),
      jwt_key,
      'RS256'
    )
  end

private

  def jwt_key
    @jwt_key || raise("Please call PSPDFKit.configure()")
  end

  def client
    @client || raise("Please call PSPDFKit.configure()")
  end

  def dig(hash, *keys)
    keys.inject(hash) { |h,k| h.is_a?(Hash) ? h[k] : nil }
  end
end
