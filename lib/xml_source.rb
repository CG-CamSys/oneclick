module XmlSource
  def to_xml(options = {})
    {skip_types: true, dasherize: false}.each do |k, v|
      options[k] = v unless options.include? k
    end
    options[:except] ||= []
    options[:except] += [:created_at, :updated_at, :id]
    super(options)
  end
end
