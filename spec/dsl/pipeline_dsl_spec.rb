describe "Rake::Pipeline::PipelineDSL" do
  ConcatFilter = Rake::Pipeline::SpecHelpers::Filters::ConcatFilter

  let(:pipeline) { Rake::Pipeline.new }
  let(:dsl) { Rake::Pipeline::DSL::PipelineDSL.new(pipeline) }

  def filter
    pipeline.filters.last
  end

  it "accepts a pipeline in its constructor" do
    dsl.pipeline.should == pipeline
  end

  describe "#input" do
    it "adds an input to the pipeline" do
      dsl.input "/app"
      pipeline.inputs["/app"].should == '**/*'
    end

    it "configures the input's glob" do
      dsl.input "/app", "*.js"
      pipeline.inputs['/app'].should == "*.js"
    end

    it "defaults input's glob to **/*" do
      dsl.input "/app"
      pipeline.inputs['/app'].should == "**/*"
    end
  end

  describe "#filter" do

    it "adds a new instance of the filter class to the pipeline's filters" do
      pipeline.filters.should be_empty
      dsl.filter ConcatFilter
      pipeline.filters.should_not be_empty
      filter.should be_kind_of(ConcatFilter)
    end

    it "takes a block to configure the filter's output file names" do
      generator = proc { |input| "main.js" }
      dsl.filter(ConcatFilter, &generator)
      filter.output_name_generator.should == generator
    end

    it "passes any extra arguments to the filter's constructor" do
      filter_class = Class.new(Rake::Pipeline::Filter) do
        attr_reader :args
        def initialize(*args)
          @args = args
        end
      end

      dsl.filter filter_class, "foo", "bar"
      filter.args.should == %w(foo bar)
    end
  end

  describe "#match" do
    it "creates a Matcher for the given glob" do
      matcher = dsl.match("*.glob") {}
      matcher.should be_kind_of(Rake::Pipeline::Matcher)
      matcher.glob.should == "*.glob"
    end

    it "adds the new matcher to the pipeline's filters" do
      matcher = dsl.match("*.glob") {}
      filter.should == matcher
    end
  end

  describe "#output" do
    it "configures the pipeline's output_root" do
      dsl.output "/path/to/output"
      pipeline.output_root.should == "/path/to/output"
    end
  end

  describe "#concat" do
    it "creates a ConcatFilter" do
      dsl.concat "octopus"
      filter.should be_kind_of(Rake::Pipeline::ConcatFilter)
    end

    context "passed an Array first argument" do
      it "creates an OrderingConcatFilter" do
        dsl.concat ["octopus"]
        filter.should be_kind_of(Rake::Pipeline::OrderingConcatFilter)
      end
    end
  end

  describe "#sort" do
    it "adds a SortedPipeline for the given comparator" do
      comparator = proc { }
      matcher = dsl.sort(&comparator)
      matcher.should be_kind_of(Rake::Pipeline::SortedPipeline)
      matcher.comparator.should == comparator
    end
  end

  describe "#copy" do
    it "creates a ConcatFilter" do
      dsl.copy
      filter.should be_kind_of(Rake::Pipeline::ConcatFilter)
    end
  end

  describe "#reject" do
    it "creates a new RejectMatcher for the given glob" do
      matcher = dsl.reject("*.glob") {}
      matcher.should be_kind_of(Rake::Pipeline::RejectMatcher)
      matcher.glob.should == "*.glob"
    end

    it "creates a new RejectMatcher with the given block" do
      block = proc { }
      matcher = dsl.reject(&block)
      matcher.should be_kind_of(Rake::Pipeline::RejectMatcher)
      matcher.block.should == block
    end

    it "adds the new reject matcher to the pipeline's filters" do
      matcher = dsl.reject("*.glob") {}
      filter.should == matcher
    end
  end

  describe "#skip" do
    it "adds a new RejectMatcher" do
      dsl.skip "*.glob"
      filter.should be_kind_of(Rake::Pipeline::RejectMatcher)
    end
  end

  describe "#exclude" do
    it "adds a new RejectMatcher" do
      dsl.exclude "*.glob"
      filter.should be_kind_of(Rake::Pipeline::RejectMatcher)
    end
  end

  describe "#gsub" do
    it "creates a GsubFilter" do
      dsl.gsub
      filter.should be_kind_of(Rake::Pipeline::GsubFilter)
    end
  end

  describe "#replace" do
    it "creates a GsubFilter" do
      dsl.replace
      filter.should be_kind_of(Rake::Pipeline::GsubFilter)
    end
  end

  describe "#strip" do
    it "creates a GsubFilter with no replacement" do
      regex = /mock/
      dsl.should_receive(:filter).with(Rake::Pipeline::GsubFilter, regex, '')
      dsl.strip /mock/
    end
  end
end
