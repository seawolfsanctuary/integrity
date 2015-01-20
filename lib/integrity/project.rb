require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :required => true, :length => 255, :unique => true
    property :permalink,  String,   :length => 255
    property :uri,        URI,      :required => true, :length => 255
    property :branch,     String,   :required => true, :length => 255, :default => "master"
    property :command,    String,   :required => true, :length => 2000, :default => "rake"
    property :artifacts,  String,   :required => false, :length => 1000
    property :public,     Boolean,  :default  => true
    property :last_build_id, Integer, :required => false
    property :coverage_provider, String

    timestamps :at

    default_scope(:default).update(:order => [:name.asc])

    has n, :builds
    has n, :notifiers
    belongs_to :last_build, 'Build'

    before :save, :set_permalink
    before :save, :fix_line_endings

    before :destroy do
      builds.destroy!
    end

    def get_artifacts
      artifacts.split(";")
    end

    def artifacts_empty?
      artifacts.nil? || artifacts.empty?
    end

    def repo
      @repo ||= Repository.new(uri, branch)
    end

    def build_head
      build(Commit.new(:identifier => "HEAD"))
    end

    def build(commit)
      _build = builds.create(:commit => {
        :identifier   => commit.identifier,
        :author       => commit.author,
        :message      => commit.message,
        :committed_at => commit.committed_at
      })
      _build.run
      _build
    end

    def fork(new_branch)
      forked = Project.create(
        :name    => "#{name} (#{new_branch})",
        :uri     => uri,
        :branch  => new_branch,
        :command => command,
        :public  => public?
      )

      notifiers.each { |notifier|
        forked.notifiers.create(
          :name    => notifier.name,
          :enabled => notifier.enabled?,
          :config  => notifier.config
        )
      }

      forked
    end

    def github?
      uri.to_s.include?("github.com")
    end

    # TODO lame, there is got to be a better way
    def sorted_builds
      builds(:order => [:created_at.desc, :id.desc])
    end

    def blank?
      last_build.nil?
    end

    def status
      blank? ? :blank : last_build.status
    end

    def human_status
      ! blank? && last_build.human_status
    end

    def human_duration
      ! blank? && last_build.human_duration
    end

    def attributes_for_json
      {
        "name" => name,
        "status" => status
      }
    end
    
    def to_json
      {
        "project" => attributes_for_json
      }.to_json
    end

    private
      def set_permalink
        attribute_set(:permalink,
          (name || "").
          downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, "")
        )
      end
      
      def fix_line_endings
        command = self.command
        unless command.empty?
          command = command.gsub("\r\n", "\n").gsub("\r", "\n")
          attribute_set(:command, command)
        end
      end
  end
end
