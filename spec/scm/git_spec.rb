require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/integrity/scm/git'

describe Integrity::SCM::Git do
  before(:each) do
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @build = mock('build model',
      :output => '',
      :error  => '',
      :status => true,
      :status= => 1
    )
    @scm = Integrity::SCM::Git.new(@uri, 'master', @build)
  end

  describe 'When asking if the repository is already cloned (#cloned?)' do
    it 'should be false if the repository git dir exists' do
      File.should_receive(:directory?).with('foo/.git').and_return(true)
      @scm.send(:cloned?, 'foo').should be_true
    end

    it 'should be false if the repository git dir doesnt exists' do
      File.should_receive(:directory?).with('foo/.git').and_return(false)
      @scm.send(:cloned?, 'foo').should be_false
    end
  end

  describe 'When asking if the repository is already on the right branch' do
    it 'should be true if .git/HEAD does point to the right branch' do
      File.should_receive(:read).with('foo/.git/HEAD').and_return("refs/heads/master\n")
      @scm.send(:on_branch?, 'foo').should be_true
    end

    it 'should be false if .git/HEAD doesnt point to it' do
      File.should_receive(:read).with('foo/.git/HEAD').and_return("refs/heads/blargh\n")
      @scm.send(:on_branch?, 'foo').should be_false
    end
  end

  describe 'When checking-out a repository' do
    before(:each) do
      @stdout = mock('io', :read => 'out')
      @stderr = mock('io', :read => 'err')
      $?.stub!(:success?).and_return(true)
      @scm.stub!(:cloned?).and_return(false)
      @scm.stub!(:on_branch?).and_return(false)
    end

    it 'should do a shallow clone of the repository into the given directory' do
      Open3.stub!(:popen3)
      Open3.should_receive(:popen3).
        with('git clone --depth 1 git://github.com/foca/integrity.git /foo/bar')
      @scm.checkout('/foo/bar')
    end

    it 'should not clone the repository if it has already been cloned' do
      Open3.stub!(:popen3)
      @scm.should_receive(:cloned?).and_return(true)
      Open3.should_not_receive(:popen3).with(/git clone/)
      @scm.checkout('/foo/bar')
    end

    it 'should switch to the specified branch' do
      Open3.stub!(:popen3)
      Open3.should_receive(:popen3).
        with('git --git-dir=/foo/bar/.git checkout master')
      @scm.checkout('/foo/bar')
    end

    it 'should switch not switch of branch if already on it' do
      @scm.should_receive(:on_branch?).and_return(true)
      Open3.should_not_receive(:popen3).with(/checkout/)
      @scm.checkout('/foo/bar')
    end

    it 'should fetch updates' do
      Open3.stub!(:popen3)
      Open3.should_receive(:popen3).with('git --git-dir=/foo/bar/.git pull')
      @scm.checkout('/foo/bar')
    end

    it "should write stdout to build's output" do
      Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
      @build.output.should_receive(:<<).with('out').exactly(3).times
      @scm.checkout('/foo/bar')
    end

    it "should write stderr to build's error" do
      Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
      @build.error.should_receive(:<<).with('err').exactly(3).times
      @scm.checkout('/foo/bar')
    end

    it "should set build's status" do
      # TODO: $?.stub!(:success?).and_return(true)
      @build.should_receive(:status=).with(boolean).exactly(3).times
      @scm.checkout('/foo/bar')
    end
  end
end