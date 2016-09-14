require 'test_helper'
require 'open-uri'

describe VCR::Archive do
  it 'has a version number' do
    refute_nil ::VCR::Archive::VERSION
  end

  describe 'Serializer'  do
    subject { VCR::Archive::Serializer }
    it 'returns "archive" as the file extension' do
      assert_equal 'archive', subject.file_extension
    end

    it "doesn't touch the hash when (de)serializing" do
      assert_equal({ foo: :bar }, subject.serialize(foo: :bar))
      assert_equal({ foo: :bar }, subject.deserialize(foo: :bar))
    end
  end

  describe 'Persister' do
    subject { VCR::Archive::Persister }

    let(:tmpdir) { Dir.mktmpdir }
    let(:uri) { 'http://example.org' }
    let(:body_string) { 'Hello, world.' }

    let(:meta) do
      {
        'http_interactions' => [
          {
            'request' => {
              'uri' => uri,
            },
            'response' => {
              'body' => {
                'string' => body_string,
              },
            },
          },
        ],
      }
    end

    let(:path) { File.join(tmpdir, 'foo', 'example.org', uri.to_s.parameterize) }
    let(:wsdl_path) { File.join(subject.storage_location, uri.to_s.parameterize) }
    let(:read_xml) { File.read("#{path}.xml") }
    let(:yaml_path) { path + '.yml' }
    let(:xml_path) { path + '.xml' }

    before { subject.storage_location = tmpdir }

    describe '#[]' do
      let(:path) { subject.storage_location + '/foo/example.com/123' }

      before { FileUtils.mkdir_p(File.dirname(path)) }

      describe 'existing files' do
        before do
          File.write(yaml_path, YAML.dump(meta['http_interactions'].first))
          xml = "<p>#{body_string}</p>"
          File.write(xml_path, xml)
          meta['http_interactions'].first['response']['body']['string'] = xml
        end

        it 'reads from the given file, relative to the configured storage location' do
          assert_equal meta, subject['foo']
        end

        it 'ignores the extension from the serializer' do
          assert_equal meta, subject['foo.archive']
        end

        it 'returns nil for unknown extensions' do
          assert_nil subject['foo.bar']
        end
      end

      it 'returns nil if the directory does not exist' do
        FileUtils.rm_rf(File.dirname(path))
        assert_nil subject['bar']
      end

      it 'returns nil if the directory exists but is empty' do
        FileUtils.mkdir_p(File.dirname(path))
        assert_nil subject['foo']
      end
    end

    describe 'existing WSDL' do
      let(:uri) { 'http://example.org?WSDL' }
      let(:path) { wsdl_path }
      let(:body_string) { 'Hello, WSDL.' }

      before { FileUtils.mkdir_p(File.dirname(path)) }

      before do
        File.write(yaml_path, YAML.dump(meta['http_interactions'].first))
        xml = "<p>#{body_string}</p>"
        File.write(xml_path, xml)
        meta['http_interactions'].first['response']['body']['string'] = xml
      end

      it 'reads WSDL file' do
        assert_equal meta, subject['foo']
      end
    end

    describe '#[]=' do
      before do
        subject['foo'] = meta
      end

      it 'writes out the metadata to a yaml file' do
        expected = { 'request'=> { 'uri' => 'http://example.org' }, 'response' => { 'body' => {} } }
        assert_equal expected, YAML.load_file("#{path}.yml")
      end

      it 'writes out response body to a xml file' do
        assert_equal body_string, read_xml
      end

      describe 'WSDL' do
        let(:uri) { 'http://example.org?WSDL' }
        let(:path) { wsdl_path }

        it 'saves WSDL file in a place that it can be reused' do
          assert_equal body_string, read_xml
        end
      end
    end
  end
end
