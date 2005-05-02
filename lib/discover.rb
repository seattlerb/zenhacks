def discover_new_classes_from
  old_classes = []
  ObjectSpace.each_object(Module) do |klass|
    old_classes << klass
  end

  yield

  new_classes = []
  ObjectSpace.each_object(Module) do |klass|
    new_classes << klass
  end

  new_classes - old_classes
end
