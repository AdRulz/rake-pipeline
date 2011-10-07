module Rake
  class Pipeline
    class UnopenedFile < StandardError
    end

    class FileWrapper < Struct.new(:root, :path)
      def ==(other)
        root == other.root && path == other.path
      end

      def hash
        [root, path].hash
      end

      def fullpath
        File.join(root, path)
      end

      def exists?
        File.exists?(fullpath)
      end

      def read
        File.read(fullpath)
      end

      def create
        FileUtils.mkdir_p(File.dirname(fullpath))
        @created_file = File.open(fullpath, "w")
      end

      def close
        raise IOError, "closed stream" unless @created_file
        @created_file.close
        @created_file = nil
      end

      def write(string)
        raise UnopenedFile unless @created_file
        @created_file.write(string)
      end

      def inspect
        "#<FileWrapper root=#{root.inspect} path=#{path.inspect}>"
      end

      alias to_s inspect
    end
  end
end
