require_relative '../../lib/ralph'
require_relative './foo'

RSpec.describe 'Foo' do
  describe '.foo' do
    it 'returns "bar"' do
      expect(Foo.foo).to eq('bar')
    end
  end
end
