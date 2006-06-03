def discover_classes
  klasses = []
  ObjectSpace.each_object(Module) { |k| klasses << k }
  klasses
end

def discover_new_classes_from
  old_classes = discover_classes
  yield
  new_classes = discover_classes
  new_classes - old_classes
end
