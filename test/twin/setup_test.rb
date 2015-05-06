require "test_helper"

class TwinSetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end


  module Twin
    class Album < Disposable::Twin
      property :id
      property :name
      collection :songs, :twin => lambda { |*| Song }
      property :artist, twin: lambda { |*| Artist }

      extend Representer
      include Setup
    end

    class Song < Disposable::Twin
      property :id
      property :composer, :twin => lambda { |*| Artist }

      extend Representer
      include Setup
    end

    class Artist < Disposable::Twin
      property :id

      extend Representer
      include Setup
    end
  end


  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:composer) { Model::Artist.new(2) }
  let (:song_with_composer) { Model::Song.new(1, "Broken", nil, composer) }
  let (:artist) { Model::Artist.new(9) }

  describe "with songs: [song, song{composer}]" do
    let (:album) { Model::Album.new(1, "The Rest Is Silence", [song, song_with_composer], artist) }

    it do
      twin = Twin::Album.new(album)

      twin.songs.size.must_equal 2
      twin.songs.must_be_instance_of Disposable::Twin::Collection

      twin.songs[0].must_be_instance_of Twin::Song
      twin.songs[0].id.must_equal 1

      twin.songs[1].must_be_instance_of Twin::Song
      twin.songs[1].id.must_equal 1
      twin.songs[1].composer.id.must_equal 2
    end
  end

  describe "with songs: [] and artist: nil" do
    let (:album) { Model::Album.new(1, "The Rest Is Silence", [], nil) }

    it do
      twin = Twin::Album.new(album)

      twin.songs.size.must_equal 0
      twin.songs.must_be_instance_of Disposable::Twin::Collection
    end
  end

  # DISCUSS: do we need to cover that (songs: nil in model)?
  # describe "with non-existent :songs" do
  #   let (:album) { Model::Album.new(1, "The Rest Is Silence", nil) }

  #   it do
  #     twin = Twin::Album.new(album)

  #     twin.songs.size.must_equal 0
  #     twin.songs.must_be_instance_of Disposable::Twin::Collection
  #   end
  # end
end

class TwinSetupWithInlineTwinsTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end

  class AlbumForm < Disposable::Twin
    extend Representer
    include Setup

    property :id
    property :name

    collection :songs do # default_inline_class: Disposable::Twin
      extend Representer
      include Setup

      property :id

      property :composer do
        extend Representer
        include Setup

        property :id
      end
    end

    property :artist do
      extend Representer
      include Setup

      property :id
    end
  end

  let (:song) { Model::Song.new(1) }
  let (:composer) { Model::Artist.new(2) }
  let (:song_with_composer) { Model::Song.new(3, composer) }
  let (:artist) { Model::Artist.new(9) }
  let (:album) { Model::Album.new(0, "Toto Live", [song, song_with_composer], artist) }

  it do
    twin = AlbumForm.new(album)
    # pp twin

    twin.id.must_equal 0
    twin.name.must_equal "Toto Live"

    twin.artist.must_be_kind_of Disposable::Twin
    twin.artist.id.must_equal 9

    twin.songs[0].must_be_kind_of Disposable::Twin
    twin.songs[0].id.must_equal 1

    twin.songs[1].must_be_kind_of Disposable::Twin
    twin.songs[1].id.must_equal 3

    twin.songs[1].composer.must_be_kind_of Disposable::Twin
    twin.songs[1].composer.id.must_equal 2
  end
end