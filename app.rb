require "roda"
require_relative "./models"

class App < Roda
  plugin :all_verbs
  plugin :public
  plugin :json
  plugin :halt
  plugin :json_parser
  plugin :render, engine: "slim"
  plugin :symbol_views
  plugin :indifferent_params

  route do |r|
    r.public

    r.root do
      { status: "ok" }
    end

    # path: /posts
    r.on "posts" do
      r.is do
        # GET
        r.get do
          {
            posts: Post.all.map(&:values)
          }
        end

        # POST
        r.post do
          r.halt(403, { errors: ["'post' params is missing"] }) unless params[:post]

          post = Post.new
          post.set_fields(params[:post], ["title", "body"])

          if post.save
            r.halt(201, { post: post.values })
          else
            r.halt(
              422,
              {
                post: post.values,
                errors: post.errors,
              }
            )
          end
        end
      end

      # path: /posts/:id
      r.on Integer do |id|
        @post = Post[id]

        r.is do
          # GET
          r.get do
            @post.to_hash.merge({
              comments_path: "/posts/#{@post.id}/comments"
            })
          end
        end

        # path: /posts/:id/comments
        r.on "comments" do
          r.is do
            # GET
            r.get do
              {
                comments: @post.comments.map(&:values)
              }
            end

            # POST
            r.post do
              r.halt(403, { errors: ["'comment' params is missing"] }) unless params[:comment]

              comment = Comment.new(post: @post)
              comment.set_fields(params[:comment], ["name", "body"])

              if comment.save
                r.halt(
                  201,
                  { comment: comment.values }
                )
              else
                r.halt(
                  422,
                  {
                    comment: comment.values,
                    errors: comment.errors
                  }
                )
              end
            end
          end
        end # /comments
      end
    end
  end

  Dir['./helpers/*.rb'].each{|f| require f}
end
