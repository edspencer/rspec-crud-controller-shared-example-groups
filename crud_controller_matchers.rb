module CrudSetup
  def setup_crud_names
    # set up the variables we'll refer to in all specs below.
    # If we had an AssetsController, these would map to:
    # @model_name                    => 'Asset'
    # @model_klass                   => Asset
    # @model_symbol                  => :Asset
    # @pluralized_model_name         => 'Assets'
    # @assigns_model_name            => :asset
    # @pluralized_assigns_model_name => :assets
    @model_name                    = @model.classify
    @model_klass                   = @model_name.constantize
    @model_symbol                  = @model_name.to_sym
    @pluralized_model_name         = @model_name.humanize.pluralize
    @assigns_model_name            = @model_name.underscore.to_sym
    @pluralized_assigns_model_name = @model_name.underscore.pluralize.to_sym
    
    # continuing AssetsController example, this maps to:
    # @stubbed_model => mock_model(Asset, :id => 1)
    # @stubbed_model_collection => [@stubbed_model]
    # Asset.stub!(:find).and_return(@stubbed_model_collection)
    @stubbed_model = mock(@model_name, :id => 1, :to_xml => 'XML', :mock_object => true)
    @stubbed_model_collection = [@stubbed_model]
    @model_klass.stub!(:find).with(:all).and_return(@stubbed_model_collection)
    
    # e.g. Asset.stub!(:count).and_return(@count)
    @count = 10
    @model_klass.stub!(:count).and_return(@count)
  end
end

describe "CRUD GET index", :shared => true do
  include CrudSetup
  
  before(:each) do
    setup_crud_names
  end
  
  it "should find all #{@pluralized_model_name}" do
    @model_klass.should_receive(:find).with(:all)
    do_get
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render the correct template" do
    do_get
    response.should render_template(:index)    
  end
  
  it "should assign the #{@pluralized_model_name} to the #{@pluralized_model_name} view variable" do
    do_get
    assigns[@pluralized_assigns_model_name].should == @stubbed_model_collection
  end
  
  it "should render the correct xml" do
    @stubbed_model_collection.should_receive(:to_xml).and_return('XML')
    do_get nil, 'xml'
    response.body.should == 'XML'
  end

  def do_get page = nil, format = 'html'
    get 'index', :format => format
  end
end

describe "CRUD GET show", :shared => true do
  include CrudSetup
  
  before(:each) do
    setup_crud_names
  end
  
  describe "with a valid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end
    
    it "should find the correct #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_get
    end
    
    it "should render the correct template when requesting HTML" do
      do_get
      response.should render_template(:show)
    end
    
    it "should render the correct XML when requesting XML" do
      @stubbed_model.should_receive(:to_xml).and_return('XML')    
      do_get 'xml'
      response.body.should == 'XML'
    end
    
    def do_get format = 'html'
      get 'show', :id => @stubbed_model.id, :format => format
    end
  end
  
  describe "with an invalid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end
    
    it "should redirect to /admin if not found via HTML" do
      do_get
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end
    
    it "should send a 404 if not found via XML" do
      do_get 'xml'
      response.headers["Status"].should == "404 Not Found"
    end
    
    def do_get format = 'html'
      get 'show', :id => -1, :format => format
    end
  end
end

describe "CRUD POST create", :shared => true do
  include CrudSetup
  
  before(:each) do
    setup_crud_names
  end
  
  describe "with valid params" do
    
    before(:each) do
      @new_stubbed_model = mock_model(@model_klass, :id => 1, :save => true, :image? => false)
      @model_klass.stub!(:new).and_return(@new_stubbed_model)
      
      @params = {"title" => 'test', "key" => "value"}
    end
    
    it "should build a new #{@model_name}" do
      @model_klass.should_receive(:new).with(@params).and_return(@new_stubbed_model)
      do_post
    end

    it "should save the #{@model_name}" do
      @new_stubbed_model.should_receive(:save).and_return(true)
      do_post
    end
    
    it "should redirect to the new #{@model_name}'s show page when requesting HTML" do
      do_post
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}/#{@new_stubbed_model.id}/edit")
    end
    
    it "should return .to_xml when requesting XML" do
      @new_stubbed_model.should_receive(:to_xml).and_return('XML')
      do_post 'xml'
      response.body.should == "XML"
    end
    
    def do_post format = 'html'
      post 'create', @assigns_model_name => @params, :format => format
    end
  end

  describe "with invalid parameters" do
    before(:each) do
      @errors = mock_model(Array, :collect => [], :full_messages => [], :add => true, :to_xml => 'XML')
      
      @new_stubbed_model = mock_model(@model_klass, :id => 1, :save => true, :image? => false, :errors => @errors)
      @new_stubbed_model.stub!(:save).and_return(false)
      @model_klass.stub!(:new).and_return(@new_stubbed_model)
      
      @params = {"title" => 'test', "key" => "value"}
    end
    
    it "should render the new template when requesting HTML" do
      do_post
      response.should render_template(:new)    
    end
    
    it "should render the errors to XML when requesting XML" do
      @errors.should_receive(:to_xml).and_return('XML')
      
      do_post 'xml'
      response.body.should == 'XML'
    end
    
    def do_post format = 'html'
      post 'create', @assigns_model_name => @params, :format => format
    end
  end
end

describe "CRUD PUT update", :shared => true do
  include CrudSetup
  
  before(:each) do
    setup_crud_names
  end
  
  describe "with valid parameters" do
    
    before(:each) do
      @stubbed_model.stub!(:update_attributes).and_return(true)
      
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end
    
    it "should find the #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_put
    end
    
    it "should save the #{@model_name}" do
      @stubbed_model.should_receive(:update_attributes).with({"title" => 'test'}).and_return(true)
      do_put
    end
    
    it "should redirect to the index path when requesting HTML" do
      do_put
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
      flash[:notice].should_not be(nil)
    end

    it "should render 200 OK for XML" do
      do_put 'xml'
      response.headers["Status"].should == "200 OK"
    end
      
    def do_put format = 'html'
      put 'update', :id => @stubbed_model.id, @assigns_model_name => {:title => 'test'}, :format => format
    end
  end

  describe "with invalid parameters" do
    before(:each) do
      @errors = mock_model(Array, :full_messages => [], :collect => [], :to_xml => 'XML')
      @stubbed_model.stub!(:errors).and_return(@errors)
      @stubbed_model.stub!(:update_attributes).and_return(false)
      
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end
    
    it "should redirect to the #{@model_name} index if the #{@model_name} was not found" do
      @model_klass.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_put
      
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")    
    end
    
    it "should render the edit action when requesting with HTML" do
      do_put
      response.should render_template(:edit)    
    end
    
    it "should render the errors to XML when requesting with XML" do  
      @errors.should_receive(:to_xml).and_return('XML')
          
      do_put 'xml'
      response.body.should == 'XML'
    end
    
    def do_put format = 'html'
      put 'update', :id => @stubbed_model.id, @assigns_model_name => {}, :format => format
    end
  end
end

describe "CRUD DELETE destroy", :shared => true do
  include CrudSetup
  
  before(:each) do
    setup_crud_names
  end
  
  describe "with a valid id" do
    
    before(:each) do
      @stubbed_model.stub!(:destroy).and_return(true)
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end
    
    it "should find the correct #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_delete
    end
    
    it "should destroy the #{@model_name}" do
      @stubbed_model.should_receive(:destroy).and_return(true)    
      do_delete
    end
    
    it "should redirect to #{@model_name} index when requesting HTML" do
      do_delete
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end

    it "should render 200 when requesting XML" do
      do_delete 'xml'
      response.headers["Status"].should == "200 OK"
    end
    
    def do_delete format = 'html'
      delete 'destroy', :id => @stubbed_model.id, :format => format
    end
  end
  
  describe "with an invalid ID" do
    
    before(:each) do
      @model_klass.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end
    
    it "should redirect to #{@model_name} index when requesting HTML" do
      do_delete
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")    
    end
    
    it "should render a 404 when requesting XML" do
      do_delete 'xml'
      response.headers["Status"].should == "404 Not Found"
    end

    def do_delete format = 'html'
      delete 'destroy', :id => -1, :format => format
    end
  end
end

describe "CRUD GET edit", :shared => true do
  include CrudSetup
  
  before(:each) do
    setup_crud_names
  end
  
  describe "with a valid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end
    
    it "should find the #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_get
    end
    
    it "should render the edit template when requesting HTML" do
      do_get
      response.should render_template(:edit)    
    end
    
    it "should be successful" do
      do_get
      response.should be_success
    end
    
    def do_get format = 'html'
      get 'edit', :id => @stubbed_model.id, :format => format
    end
  end
  
  describe "with an invalid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end
    
    it "should redirect to the #{@model_name} index when requesting HTML" do
      do_get
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")    
    end

    it "should render a 404 when requesting XML" do
      do_get 'xml'
      response.headers["Status"].should == "404 Not Found"
    end
    
    def do_get format = 'html'
      get 'edit', :id => -1, :format => format
    end
  end
end
