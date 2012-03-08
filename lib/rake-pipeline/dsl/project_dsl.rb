# encoding: utf-8
module Rake
  class Pipeline
    module DSL
      # This class exists purely to provide a convenient DSL for
      # configuring a project.
      #
      # All instance methods of {ProjectDSL} are available in the context
      # the block passed to +Rake::Pipeline::Project.+{Project.build}.
      #
      # When configuring a project, you *must* provide an output root
      # and a series of files using at least one {#input} block.
      class ProjectDSL
        # @return [Project] the project the DSL should configure
        attr_reader :project

        # Configure a project with a passed in block.
        #
        # @param [Project] project the project that the ProjectDSL
        #   should configure.
        # @param [Proc] block the block describing the
        #   configuration. This block will be evaluated in
        #   the context of a new instance of {ProjectDSL}
        # @return [void]
        def self.evaluate(project, &block)
          new(project).instance_eval(&block)
        end

        # Create a new {ProjectDSL} to configure a project.
        #
        # @param [Project] project
        #   the project that the ProjectDSL should configure.
        # @return [void]
        def initialize(project)
          @project = project
        end

        # Specify the default output directory for the project.
        #
        # Pipelines created in this project will place their
        # outputs here unless the value is overriden in their
        # {#input} block.
        #
        # @param [String] root the output directory.
        # @return [void]
        def output(root)
          project.default_output_root = root
        end

        # Specify the location of the root temporary directory.
        #
        # Pipelines will store intermediate build artifacts
        # in a subdirectory of this directory.
        #
        # This defaults to "tmp" in the current working directory.
        #
        # @param [String] root the temporary directory
        # @return [void]
        def tmpdir(root)
          project.tmpdir = root
        end

        # Add a new pipeline with the given inputs to the project.
        #
        # @see Project.build_pipeline
        def input(*inputs, &block)
          project.build_pipeline(*inputs, &block)
        end
        alias inputs input
      end
    end
  end
end
