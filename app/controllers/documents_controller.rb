class DocumentsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    render :unauthorized, status: :forbidden
  end

  def index
    @user = current_user
    @documents = current_user.documents
  end

  def create
    unless params[:document].try(:tempfile).present?
      redirect_to new_document_path
      return
    end

    result = PSPDFKit.upload_document(params[:document].tempfile)
    PSPDFKit.document_change_permissions(result[:id], add_users: [current_user.id])

    document = current_user.documents.create(
      server_id: result[:id],
      title: result[:title].presence || File.basename(params[:document].original_filename, ".pdf") || "Untitled"
    )

    redirect_to documents_path
  end

  def show
    @document = current_user.documents.find(params[:id])
    @all_users = User.all
    @permitted_users = @document.users
    if params[:instant].present?
      session[:instant] = params[:instant] == 'true'
    end
  end

  def permissions
    new_user_ids = (params[:users] || []).map(&:to_s)

    document = current_user.documents.find(params[:id])
    old_user_ids = document.users.map {|u| u.id.to_s }
    document.user_ids = new_user_ids

    PSPDFKit.document_change_permissions(
      document.server_id,
      remove_users: old_user_ids - new_user_ids,
      add_users: new_user_ids - old_user_ids
    )

    redirect_to document
  end
end
