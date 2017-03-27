require 'barby'
require 'barby/barcode/qr_code'
require 'barby/outputter/svg_outputter'
require 'digest'

module Chemotion
  class AttachmentAPI < Grape::API
    resource :attachments do

      #todo: move to AttachmentAPI
      desc "Upload attachments"
      post 'upload_dataset_attachments' do
        params.each do |file_id, file|
          if tempfile = file.tempfile
            begin
              sha256 = Digest::SHA256.file(tempfile).hexdigest

              storage = Storage.new
              storage.create(file_id, file.filename, IO.binread(tempfile), sha256, current_user.id, current_user.id)
            ensure
              tempfile.close
              tempfile.unlink   # deletes the temp file
            end
          end
        end
        true
      end

      #todo: authorize attachment download
      desc "Download the attachment file"
      get ':attachment_id' do
        attachment_id = params[:attachment_id]

        attachment = Attachment.find_by id: attachment_id
        if attachment != nil
          storage = Storage.new

          content_type "application/octet-stream"
          header['Content-Disposition'] = "attachment; filename="+attachment.filename
          env['api.format'] = :binary

          storage.read(attachment)
        else
          nil
        end
      end

      #todo: authorize attachment download
      desc "Download the zip attachment file"
      get 'zip/:container_id' do
        container_id = params[:container_id]

        if Container.exists?(id: container_id)

        end
      end

      resource :thumbnail do
        desc 'Return Base64 encoded thumbnail'
        get ':id' do

          attachment = Attachment.find_by id: params[:id]
          if attachment
            storage = Storage.new
            storage.read_thumbnail(attachment)
          else
            nil
          end
        end
      end

      namespace :svgs do
        desc "Get QR Code SVG for element"
        params do
          requires :element_id, type: Integer
          requires :element_type, type: String
        end
        get do
          case params[:element_type]
          when "sample"
            sample = Sample.find(params[:element_id])
            qr_code = Barby::QrCode.new(sample.qr_code, size: 1, level: :l)
            outputter = Barby::SvgOutputter.new(qr_code)
            outputter.to_svg(margin: 0)
          when "wellplate"
            wellplate = Wellplate.find(params[:element_id])
            qr_code = Barby::QrCode.new(wellplate.qr_code, size: 1, level: :l)
            outputter = Barby::SvgOutputter.new(qr_code)
            outputter.to_svg(margin: 0)
          else
            ""
          end
        end
      end

    end
  end
end
