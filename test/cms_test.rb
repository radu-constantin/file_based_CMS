ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def setup
		FileUtils.mkdir_p(data_path)
	end

	def teardown
		FileUtils.rm_rf(data_path)
	end

	def create_document(name, content = "")
		File.open(File.join(data_path, name), "w") do |file|
			file.write(content)
		end
	end

	def test_index
		create_document "about.md"
		create_document "changes.txt"

		get "/"

		assert_equal 200, last_response.status
		assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
		assert_includes last_response.body, "about.md"
		assert_includes last_response.body, "changes.txt"
	end

	def test_history
		create_document "history.txt"

		get "/history.txt"

		assert_equal 200, last_response.status
		assert_equal "text/plain", last_response["Content-Type"]
	end

	def test_about
		create_document "about.md"

		get "/about.md"

		assert_equal 200, last_response.status
		assert_includes last_response["Content-Type"], "text/html"
	end

	def test_unexistent_file
		get "/unexistent_file.txt"
		assert_equal 302, last_response.status
		get last_response["Location"]
		assert_equal 200, last_response.status
  	assert_includes last_response.body, "unexistent_file.txt does not exist"
		get "/" # Reload the page
  	refute_includes last_response.body, "unexistent_file.txt does not exist"
	end

	def test_viewing_markdown_document
		create_document "about.md"

		get "/about.md"

		assert_equal 200, last_response.status
		assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
	end
end
