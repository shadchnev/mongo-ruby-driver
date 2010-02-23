require 'test/test_helper'

class ObjectIDTest < Test::Unit::TestCase

  include Mongo

  def setup
    @o = ObjectID.new
  end

  def test_hashcode
    assert_equal @o.instance_variable_get(:@data).hash, @o.hash
  end

  def test_array_uniq_for_equilavent_ids
    a = ObjectID.new('123')
    b = ObjectID.new('123')
    assert_equal a, b
    assert_equal 1, [a, b].uniq.size
  end

  def test_create_pk_method
    doc = {:name => 'Mongo'}
    doc = ObjectID.create_pk(doc)
    assert doc[:_id]

    doc = {:name => 'Mongo', :_id => '12345'}
    doc = ObjectID.create_pk(doc)
    assert_equal '12345', doc[:_id]
  end

  def test_different
    a = ObjectID.new
    b = ObjectID.new
    assert_not_equal a.to_a, b.to_a
    assert_not_equal a, b
  end

  def test_eql?
    o2 = ObjectID.new(@o.to_a)
    assert_equal @o, o2
  end

  def test_to_s
    s = @o.to_s
    assert_equal 24, s.length
    s =~ /^([0-9a-f]+)$/
    assert_equal 24, $1.length
  end

  def test_save_and_restore
    host = ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost'
    port = ENV['MONGO_RUBY_DRIVER_PORT'] || Connection::DEFAULT_PORT
    db = Connection.new(host, port).db('ruby-mongo-test')
    coll = db.collection('test')

    coll.remove
    coll << {'a' => 1, '_id' => @o}

    row = coll.find().collect.first
    assert_equal 1, row['a']
    assert_equal @o, row['_id']
  end

  def test_from_string
    hex_str = @o.to_s
    o2 = ObjectID.from_string(hex_str)
    assert_equal hex_str, o2.to_s
    assert_equal @o, o2
    assert_equal @o.to_s, o2.to_s
  end

  def test_illegal_from_string
    assert_raise InvalidObjectID do 
      ObjectID.from_string("")
    end
  end

  def test_legal
    assert !ObjectID.legal?(nil)
    assert !ObjectID.legal?("fred")
    assert !ObjectID.legal?("0000")
    assert !ObjectID.legal?('000102030405060708090A0')
    assert ObjectID.legal?('000102030405060708090A0B')
    assert ObjectID.legal?('abcdefABCDEF123456789012')
    assert !ObjectID.legal?('abcdefABCDEF12345678901x')
  end

  def test_from_string_leading_zeroes
    hex_str = '000000000000000000000000'
    o = ObjectID.from_string(hex_str)
    assert_equal hex_str, o.to_s
  end

  def test_byte_order
    hex_str = '000102030405060708090A0B'
    o = ObjectID.from_string(hex_str)
    assert_equal [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b], o.to_a
  end

  def test_generation_time
    time = Time.now
    id   = ObjectID.new
    generated_time = id.generation_time

    assert_in_delta time.to_i, generated_time.to_i, 2
    assert_equal "UTC", generated_time.zone
  end

  def test_from_time
    time = Time.now.utc
    id   = ObjectID.from_time(time)

    assert_equal time.to_i, id.generation_time.to_i
  end

  def test_json
    id = ObjectID.new
    assert_equal "{\"$oid\": \"#{id}\"}", id.to_json
  end
end