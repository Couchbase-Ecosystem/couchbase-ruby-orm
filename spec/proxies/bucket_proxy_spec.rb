require 'couchbase-orm/proxies/bucket_proxy'
require 'couchbase-orm/proxies/n1ql_proxy'
require 'couchbase-orm/proxies/results_proxy'

RSpec.describe CouchbaseOrm::BucketProxy do
    let(:proxyfied) { double('bucket') }

    it 'raises when asked to proxy nil' do
        expect { CouchbaseOrm::BucketProxy.new(nil) }.to raise_error(ArgumentError)
    end

    it 'delegates unknown methods to the proxyfied object' do
        allow(proxyfied).to receive(:name).and_return('my_bucket')
        expect(CouchbaseOrm::BucketProxy.new(proxyfied).name).to eq('my_bucket')
    end

    it 'delegates unknown methods with args, kwargs and a block' do
        allow(proxyfied).to receive(:default_collection).with('a', b: 1).and_yield(:yielded)
        CouchbaseOrm::BucketProxy.new(proxyfied).default_collection('a', b: 1) do |arg|
            expect(arg).to eq(:yielded)
        end
    end

    it 'wraps #n1ql in a N1qlProxy' do
        allow(proxyfied).to receive(:n1ql).and_return(:the_n1ql)
        expect(CouchbaseOrm::BucketProxy.new(proxyfied).n1ql).to be_a(CouchbaseOrm::N1qlProxy)
    end

    describe '#view' do
        it 'wraps the result in a ResultsProxy and caches it for the same design/view' do
            allow(proxyfied).to receive(:view).with('design', 'view').and_return([:row1, :row2])
            proxy = CouchbaseOrm::BucketProxy.new(proxyfied)

            first = proxy.view('design', 'view')
            second = proxy.view('design', 'view')

            expect(first).to be_a(CouchbaseOrm::ResultsProxy)
            expect(second).to be(first)
            expect(proxyfied).to have_received(:view).once
        end

        it 'requeries when the design/view pair changes' do
            allow(proxyfied).to receive(:view).with('design', 'view').and_return([:row1])
            allow(proxyfied).to receive(:view).with('design', 'other').and_return([:row2])
            proxy = CouchbaseOrm::BucketProxy.new(proxyfied)

            proxy.view('design', 'view')
            proxy.view('design', 'other')

            expect(proxyfied).to have_received(:view).twice
        end
    end
end
