conversis-splunk
================

Small ruby lib to access the Splunk API

# Example
  ```ruby
  splunk = Conversis::Splunk::Client.new(host: splunk_server, username: splunk_login, password: splunk_password)
  search_id = splunk.search(splunk_query)
  splunk.wait_for(search_id)
  pp splunk.results(search_id)
  ```
