module Rake
  class Pipeline
    # This class exists purely to provide a convenient DSL for
    # configuring a pipeline.
    #
    # All instance methods of {DSL} are available in the context
    # the block passed to +Rake::Pipeline.+{Pipeline.build}.
    #
    # When configuring a pipeline, you *must* provide both a
    # root, and a series of files using {#input}.
    class DSL
      # @return [Pipeline] the pipeline the DSL should configure
      attr_reader :pipeline

      # Configure a pipeline with a passed in block.
      #
      # @param [Pipeline] pipeline the pipeline that the DSL
      #   should configure.
      # @param [Proc] block the block describing the
      #   configuration. This block will be evaluated in
      #   the context of a new instance of {DSL}
      # @return [void]
      def self.evaluate(pipeline, &block)
        new(pipeline).instance_eval(&block)
      end

      # Create a new {DSL} to configure a pipeline.
      #
      # @param [Pipeline] pipeline the pipeline that the DSL
      #   should configure.
      # @return [void]
      def initialize(pipeline)
        @pipeline = pipeline
      end

      # Define the input location and files for the pipeline.
      #
      # @example
      #   !!!ruby
      #   Rake::Pipeline.build do
      #     input "app/assets", "**/*.js"
      #     # ...
      #   end
      #
      # @param [String] root the root path where the pipeline
      #   should find its input files.
      # @param [String] glob a file pattern that represents
      #   the list of all files that the pipeline should
      #   process. The default is +"**/*"+.
      # @return [void]
      def input(root, glob="**/*")
        pipeline.input_root = root
        pipeline.input_glob = glob
      end

      # Add a filter to the pipeline.
      #
      # In addition to a filter class, {#filter} takes a
      # block that describes how the filter should map
      # input files to output files.
      #
      # By default, the block maps an input file into
      # an output file with the same name.
      #
      # You can also specify a +String+, which will map
      # all input files into the same output file. This
      # is useful when you want to concatenate a list of
      # files together.
      #
      # @see Filter#outputs Filter#output (for an example
      #   of how a list of input files gets mapped to
      #   its outputs)
      #
      # @param [Class] filter_class the class of the filter.
      # @param [String] string an output file name.
      # @param [Proc] block an output file name generator
      # @return [void]
      def filter(filter_class, string=nil, &block)
        block ||= if string
          proc { string }
        else
          proc { |input| input }
        end

        filter = filter_class.new
        filter.output_name_generator = block
        pipeline.add_filter(filter)
      end

      def match(pattern, &block)
        matcher = pipeline.copy(Matcher, &block)
        matcher.glob = pattern
        pipeline.add_filter matcher
        matcher
      end

      # Specify the output directory for the pipeline.
      #
      # @param [String] root the output directory.
      # @return [void]
      def output(root)
        pipeline.output_root = root
      end

      # Specify the location of the temporary directory.
      # Filters will store intermediate build artifacts
      # here.
      #
      # This defaults "tmp" in the current working directory.
      #
      # @param [String] root the temporary directory
      # @return [void]
      def tmpdir(root)
        pipeline.tmpdir = root
      end

      # Specify a rake application to use for the pipeline.
      #
      # You should rarely have to use this unless you know
      # what you're doing. This defaults to +Rake.application+.
      #
      # @api private
      # @param [Rake::Application] app a +Rake::Application+
      # @return [void]
      def rake_application(app)
        pipeline.rake_application = app
      end
    end
  end
end


