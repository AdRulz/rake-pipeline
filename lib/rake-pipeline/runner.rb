module Rake
  class Pipeline
    # A Runner controls the lifecycle of a Pipeline, creating
    # it from an Assetfile and recreating it if the Assetfile
    # changes.
    #
    class Runner
      include FileUtils

      # @return [Pipeline] the pipeline this Runner is controlling.
      attr_reader :pipeline

      # @return [String|nil] the path to the {#pipeline}'s Assetfile
      #   or nil if it was created without an Assetfile.
      attr_reader :assetfile_path

      # @return [String|nil] the digest of the Assetfile the
      #   {#pipeline} was created with, or nil if {#pipeline}
      #   was created without an Assetfile.
      attr_reader :assetfile_digest

      # @param [String|Rake::Pipeline] assetfile_or_pipeline
      #   if this a String, create a Rake::Pipeline from the
      #   Assetfile at that path. If it's a Rake::Pipeline,
      #   just wrap that pipeline
      def initialize(assetfile_or_pipeline)
        if assetfile_or_pipeline.is_a?(String)
          @assetfile_path = File.expand_path(assetfile_or_pipeline)
          build_pipeline
        else
          @pipeline = assetfile_or_pipeline
        end
      end

      # Clean out old tmp directories from the pipeline's
      # {Rake::Pipeline#tmpdir}.
      #
      # @return [void]
      def cleanup_tmpdir
        pipeline.setup_filters

        if File.directory?(pipeline.tmpdir)
          old_dirs = Dir["#{pipeline.tmpdir}/rake-pipeline-*"].reject do |dir|
            dir == "#{pipeline.tmpdir}/#{digested_tmpdir}"
          end

          old_dirs.each { |dir| rm_rf dir }
        end
      end

      # Remove the contents of this pipeline's {#tmpdir} and all of
      # its {#output_files}.
      #
      # @return [void]
      def clobber
        cleanup_tmpdir

        rm_rf "#{pipeline.tmpdir}/#{digested_tmpdir}"

        pipeline.output_files.each do |file|
          rm_rf file.fullpath
        end
      end

      # Invoke the pipeline.
      #
      # @return [void]
      # @see Rake::Pipeline#invoke
      def invoke
        pipeline.invoke
      end

      # Invoke the pipeline, detecting any changes to the Assetfile
      # and rebuilding the pipeline if necessary.
      #
      # @return [void]
      # @see Rake::Pipeline#invoke_clean
      def invoke_clean
        if assetfile_path
          assetfile_source = File.read(assetfile_path)
          if digest(assetfile_source) != assetfile_digest
            build_pipeline(assetfile_source)
          end
        end
        pipeline.invoke_clean
      end

      # @return [String] the directory name to use as the pipeline's
      #   {Rake::Pipeline#tmpsubdir}.
      def digested_tmpdir
        "rake-pipeline-#{assetfile_digest}"
      end

    private
      # Build a new pipeline based on the Assetfile at
      # {#assetfile_path}
      #
      # @return [void]
      def build_pipeline(assetfile_source=nil)
        assetfile_source ||= File.read(assetfile_path)
        @assetfile_digest = digest(assetfile_source)
        @pipeline = Rake::Pipeline.class_eval("build do\n#{assetfile_source}\nend", assetfile_path, 1)
        @pipeline.tmpsubdir = digested_tmpdir
        cleanup_tmpdir
      end

      # @return [String] the SHA1 digest of the given string.
      def digest(str)
        (Digest::SHA1.new << str).to_s
      end
    end
  end
end
