module AbakCrossposting
  module Facebook
    # Posting to facebook public group wall
    #
    # Usage
    #   post = { :message => 'Hello, Facebook!', :picture => 'path/to/my_photo.jpg' }
    #   group = { :id => 123, :access_token => 'aCCEssToKEN' }
    #   publisher = AbakCrossposting::Facebook::Publisher.new post, group
    #   publisher.run
    class Publisher
      require 'ostruct'
      require 'koala'
      require 'abak_crossposting/base/post'

      def self.run(post, groups)
        results = []
        groups.each { |_group| results << self.new(post, _group).run }
        results
      end

      attr_reader :post, :group

      # @param [Hash] post  Content for posting (message, link, picture)
      # @param [Hash] group Facebook group details (id, token)
      def initialize(post, group)
        @post  = Post.new post
        @group = Group.new group
      end

      def run
        response = api.send(post.posting_method, post.content, post.options, group.id)
        {post_id: post_id(response)}
      rescue ::Koala::KoalaError => e
        {error: e.message}
      end

      private

      class Group < OpenStruct; end

      class Post < Base::Post

        def posting_method
          has_picture? ? :put_picture : :put_wall_post
        end

        def content
          has_picture? ? picture : message
        end

        def options
          if has_picture? && has_message?
            {message: message}
          elsif has_link?
            {link: link}
          else
            {}
          end
        end
      end

      def api
        return @api if @api

        user_api = ::Koala::Facebook::API.new(group.access_token)
        page_token = user_api.get_page_access_token(group.id)
        @api = ::Koala::Facebook::API.new(page_token)
      end

      def post_id response
        post.has_picture? ? response["post_id"] : response["id"]
      end

    end
  end
end