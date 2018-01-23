class Faraday::Response
  def assert_success!
    return self if success?
    raise Faraday::Error, "Received HTTP #{status}."
  end
end
