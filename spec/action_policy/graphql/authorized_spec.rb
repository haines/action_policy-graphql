# frozen_string_literal: true

require "spec_helper"

describe "authorize: *, authorized_scope: *", :aggregate_failures do
  include_context "common:graphql"

  let(:user) { :user }

  let(:schema) { Schema }
  let(:context) { {user: user} }

  context "authorized_scope: *" do
    let(:posts) { [Post.new("private-a"), Post.new("public-b")] }
    let(:query) do
      %({
          posts {
            title
          }
        })
    end

    before do
      allow(Schema).to receive(:posts) { posts }
    end

    it "has authorized scope" do
      expect { subject }.to have_authorized_scope(:data)
        .with(PostPolicy)
    end

    specify "as user" do
      expect(data.size).to eq 1
      expect(data.first.fetch("title")).to eq "public-b"
    end

    context "as admin" do
      let(:user) { :admin }

      specify do
        expect(data.size).to eq 2
        expect(data.map { |v| v.fetch("title") }).to match_array(
          [
            "private-a",
            "public-b"
          ]
        )
      end
    end
  end

  context "authorize: *" do
    let(:post) { Post.new("private-a") }
    let(:query) do
      %({
          authPost {
            title
          }
        })
    end

    before do
      allow(Schema).to receive(:post) { post }
    end

    it "is authorized" do
      expect { subject }.to be_authorized_to(:show?, post)
        .with(PostPolicy)
    end

    specify "as user" do
      expect { subject }.to raise_error(ActionPolicy::Unauthorized)
    end

    context "accessible resource" do
      let(:post) { Post.new("post-c-visible") }

      specify do
        expect(data.fetch("title")).to eq "post-c-visible"
      end
    end

    context "as admin" do
      let(:user) { :admin }

      specify do
        expect(data.fetch("title")).to eq "private-a"
      end
    end

    context "with options" do
      let(:query) do
        %({
            anotherPost {
              title
            }
          })
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:preview?, post)
          .with(AnotherPostPolicy)
      end
    end

    context "non-raising authorize" do
      let(:query) do
        %({
            nonRaisingPost {
              title
            }
          })
      end

      it "returns nil" do
        expect(data).to be_nil
      end
    end
  end
end