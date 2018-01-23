describe CoinAPI do
  describe '#http_post_request' do
    it 'raises custom error on connection refused' do
      Net::HTTP.any_instance.stubs(:request).raises(Errno::ECONNREFUSED)

      expect do
        CoinAPI[:btc].http_post_request '/wrong'
      end.to raise_error(CoinAPI::ConnectionRefusedError)
    end
  end
end
