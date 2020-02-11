require 'yaml'
require 'open3'

puts ARGV.inspect
output = `skaffold render`

yamls =output.split('---').map { |s|  YAML.load(s) }
depl = yamls.find do |m|
  m['kind'] == "Deployment" && m.dig('spec', 'template', 'metadata', 'labels', 'app.kubernetes.io/utility-pod-origin') == 'true'
end

app = depl.dig('spec', 'template', 'metadata', 'labels', 'app')
container = depl.dig('spec', 'template', 'spec', 'containers').first
image = container['image']

ex = `kubectl get pods | awk '{print $1}'`.split("\n").find { |s| s.include?(app + "-utility") }
if ex
  # cmd = ("kubectl attach #{ex} -c #{app}-utility -i -t")
  cmd = "kubectl exec -it #{ex} -- #{ARGV.join(' ')}"
  puts cmd
  exec(cmd)
else
  cmd = "kubectl run -it #{app}-utility --image #{image} --env RACK_ENV=development --labels app.kubernetes.io/ksync=true -- #{ARGV.count > 0 ? ARGV.join(' ') : 'bash'}"
  puts cmd
  exec(cmd)
end
