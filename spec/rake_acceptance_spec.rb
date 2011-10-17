describe "A realistic pipeline" do

INPUTS = {

"app/javascripts/jquery.js" => <<-HERE,
var jQuery = {};
HERE

"app/javascripts/sproutcore.js" => <<-HERE,
var SC = {};
assert(SC);
SC.hi = function() { console.log("hi"); };
HERE

"app/stylesheets/jquery.css" => <<-HERE,
#jquery {
  color: red;
}
HERE

"app/stylesheets/sproutcore.css" => <<-HERE
#sproutcore {
  color: green;
}
HERE

}

EXPECTED_JS_OUTPUT = <<-HERE
var jQuery = {};
var SC = {};

SC.hi = function() { console.log("hi"); };
HERE

EXPECTED_CSS_OUTPUT = <<-HERE
#jquery {
  color: red;
}
#sproutcore {
  color: green;
}
HERE

  class ConcatFilter < Rake::Pipeline::Filter
    def generate_output(inputs, output)
      inputs.each do |input|
        output.write input.read
      end
    end
  end

  class StripAssertsFilter < Rake::Pipeline::Filter
    def generate_output(inputs, output)
      inputs.each do |input|
        output.write input.read.gsub(%r{^\s*assert\(.*\)\s*;?\s*$}m, '')
      end
    end
  end

  before do
    Rake.application = Rake::Application.new

    INPUTS.each do |name, string|
      mkdir_p File.dirname(File.join(tmp, name))
      File.open(File.join(tmp, name), "w") { |file| file.write(string) }
    end
  end

  def output_should_exist(expected = EXPECTED_JS_OUTPUT)
    output = File.join(tmp, "public/javascripts/application.js")
    temp   = File.join(tmp, "temporary")

    File.exists?(output).should be_true
    File.exists?(temp).should be_true

    File.read(output).should == expected
  end

  it "can successfully apply filters" do
    concat = ConcatFilter.new
    concat.input_root = tmp
    concat.input_files = INPUTS.keys.select { |key| key =~ /javascript/ }
    concat.output_root = File.join(tmp, "temporary", "concat_filter")
    concat.output_name = proc { |input| "javascripts/application.js" }

    strip_asserts = StripAssertsFilter.new
    strip_asserts.input_root = concat.output_root
    strip_asserts.input_files = concat.outputs.keys.map { |file| file.path }
    strip_asserts.output_root = File.join(tmp, "public")
    strip_asserts.output_name = proc { |input| input }

    concat.rake_tasks
    Rake::Task.define_task(:default => strip_asserts.rake_tasks)
    Rake.application[:default].invoke

    output_should_exist
  end

  it "can be configured using the pipeline" do
    pipeline = Rake::Pipeline.new
    pipeline.input_root = File.expand_path(tmp)
    pipeline.output_root = File.expand_path("public")
    pipeline.input_files = "app/javascripts/*.js"
    pipeline.tmpdir = "temporary"

    concat = ConcatFilter.new
    concat.output_name = proc { |input| "javascripts/application.js" }

    strip_asserts = StripAssertsFilter.new
    strip_asserts.output_name = proc { |input| input }

    pipeline.add_filters(concat, strip_asserts)
    pipeline.invoke

    output_should_exist
  end

  describe "using the pipeline DSL" do

    attr_reader :pipeline

    shared_examples_for "the pipeline DSL" do
      it "can be configured using the pipeline DSL" do
        pipeline.invoke
        output_should_exist
      end

      it "can be configured using the pipeline DSL with an alternate Rake application" do
        pipeline.rake_application = Rake::Application.new
        pipeline.invoke
        output_should_exist
      end

      it "can be invoked repeatedly to reflected updated changes" do
        pipeline.invoke
        age_existing_files

        File.open(File.join(tmp, "app/javascripts/jquery.js"), "w") do |file|
          file.write "var jQuery = {};\njQuery.trim = function() {};\n"
        end

        expected = <<-HERE.gsub(/^ {10}/, '')
          var jQuery = {};
          jQuery.trim = function() {};
          var SC = {};

          SC.hi = function() { console.log("hi"); };
        HERE

        $billy = true
        pipeline.invoke
        $billy = false

        output_should_exist(expected)
      end

      it "can be restarted to reflect new files" do
        pipeline.invoke
        age_existing_files

        File.open(File.join(tmp, "app/javascripts/history.js"), "w") do |file|
          file.write "var History = {};\n"
        end

        pipeline.invoke_clean

        expected = <<-HERE.gsub(/^ {10}/, '')
          var History = {};
          var jQuery = {};
          var SC = {};

          SC.hi = function() { console.log("hi"); };
        HERE

        output_should_exist(expected)
      end
    end

    describe "the raw pipeline DSL" do
      it_behaves_like "the pipeline DSL"

      before do
        @pipeline = Rake::Pipeline.build do
          tmpdir "temporary"
          input tmp, "app/javascripts/*.js"
          filter(ConcatFilter) { "javascripts/application.js" }
          filter(StripAssertsFilter) { |input| input }
          output "public"
        end
      end
    end

    describe "the raw pipeline DSL" do
      it_behaves_like "the pipeline DSL"

      before do
        @pipeline = Rake::Pipeline.build do
          tmpdir "temporary"
          input tmp, "app/javascripts/*.js"
          filter ConcatFilter, "javascripts/application.js"
          filter StripAssertsFilter
          output "public"
        end
      end
    end

    describe "a nested pipeline DSL" do
      it_behaves_like "the pipeline DSL"

      def output_should_exist(expected=EXPECTED_JS_OUTPUT)
        super

        css    = File.join(tmp, "public/stylesheets/application.css")

        File.exists?(css).should be_true
        File.read(css).should == EXPECTED_CSS_OUTPUT
      end

      before do
        @pipeline = Rake::Pipeline.build do
          tmpdir "temporary"
          input tmp
          output "public"

          files "app/javascripts/*.js" do
            filter ConcatFilter, "javascripts/application.js"
            filter StripAssertsFilter
          end

          files "app/stylesheets/*.css" do
            filter ConcatFilter, "stylesheets/application.css"
          end
        end
      end
    end
  end
end
