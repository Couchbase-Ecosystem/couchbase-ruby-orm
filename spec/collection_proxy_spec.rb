require File.expand_path("../support", __FILE__)
require File.expand_path("../../lib/couchbase-orm/proxies/collection_proxy", __FILE__)

class Proxyfied
    def get(key, options = nil)
       raise Couchbase::Error::DocumentNotFound
    end
    def remove(key, options = nil)
        raise Couchbase::Error::DocumentNotFound
    end
end

describe CouchbaseOrm::CollectionProxy do
    it "should raise an error when get is called with bang version" do
        expect { CouchbaseOrm::CollectionProxy.new(Proxyfied.new).get!('key') }.to raise_error(Couchbase::Error::DocumentNotFound)
    end

    it "should not raise an error when get is called with non bang version" do
        expect { CouchbaseOrm::CollectionProxy.new(Proxyfied.new).get('key') }.to_not raise_error
    end

    it "should raise an error when remove is called with bang version" do
        expect { CouchbaseOrm::CollectionProxy.new(Proxyfied.new).remove!('key') }.to raise_error(Couchbase::Error::DocumentNotFound)
    end

    it "should not raise an error when remove is called with non bang version" do
        expect { CouchbaseOrm::CollectionProxy.new(Proxyfied.new).remove('key') }.to_not raise_error
    end
end
