describe "Rake::Pipeline::FileWrapper" do
  let(:file)   { Rake::Pipeline::FileWrapper.new }
  let(:root)   { File.expand_path("app/assets") }
  let(:jquery) { File.join(root, "javascripts/jquery.js") }

  before do
    file.root = root
    file.path = "javascripts/jquery.js"
  end

  it "has a fullpath" do
    file.fullpath.should == jquery
  end

  it "it knows it doesn't exist when the file doesn't exist" do
    file.exists?.should == false
  end

  it "knows it exists when the file exists" do
    touch_p jquery
    file.exists?.should == true
  end

  it "raises an exception if trying to #read a file that doesn't exist" do
    lambda { file.read }.should raise_error(Errno::ENOENT)
  end

  it "returns the file's body when invoking #read on a file that does exist" do
    touch_p jquery
    body = "This. Is. jQuery!"
    File.open(jquery, "w") { |file| file.write body }

    file.read.should == body
  end

  it "creates a file with #create" do
    new_file = file.create
    new_file.should be_kind_of File

    File.exists?(jquery).should == true

    new_file.close
  end

  it "complains if trying to close an unopened file" do
    lambda { file.close }.should raise_error(IOError)
  end

  it "closes a file created using #create with #close" do
    new_file = file.create
    new_file.closed?.should == false

    file.close
    new_file.closed?.should == true

    lambda { file.close }.should raise_error(IOError)
  end

  it "complains if trying to write to a file that was not created" do
    lambda { file.write "This. Is. jQuery" }.should raise_error(Rake::Pipeline::UnopenedFile)
  end

  it "writes to the file system if the file was created" do
    new_file = file.create
    file.write "This. Is. jQuery"
    new_file.close

    file.read.should == "This. Is. jQuery"
  end
end
