module Rake
  class Pipeline
    class Filter
      attr_accessor :input_files
      attr_accessor :output_name
      attr_accessor :input_root
      attr_accessor :output_root

      def outputs
        hash = {}

        input_files.each do |file|
          output = output_wrapper(output_name.call(file))

          hash[output] ||= []
          hash[output] << input_wrapper(file)
        end

        hash
      end

    private
      def input_wrapper(file)
        FileWrapper.new(input_root, file)
      end

      def output_wrapper(file)
        FileWrapper.new(output_root, file)
      end
    end
  end
end
