class UpdateAllSshGitRepoUrlsToHttps < ActiveRecord::Migration[5.2]
  def change
    Service.all.each do |service|
      if service.git_repo_url =~ /git@github.com:/
        https_url = service.git_repo_url.gsub('git@github.com:', 'https://github.com/')
        Rails.logger.info [service.slug, service.git_repo_url, https_url].join("=>")
        service.update_attributes(
          git_repo_url: https_url
        )
      end
    end
  end
end
