## kuby-kind

Kind provider for [Kuby](https://github.com/getkuby/kuby-core).

## Intro

In Kuby parlance, a "provider" is an [adapter](https://en.wikipedia.org/wiki/Adapter_pattern) that enables Kuby to deploy apps to a specific cloud provider. In this case, we're talking about [Kind](https://kind.sigs.k8s.io/), which is a tool that makes it easy to run local, ephemeral Kubernetes clusters.

All providers adhere to a specific interface, meaning you can swap out one provider for another without having to change your code.

## Usage

Enable the Kind provider like so:

```ruby
Kuby.define('MyApp') do
  environment(:production) do
    kubernetes do

      provider :kind

    end
  end
end
```

Once configured, you should be able to run all the Kuby commands as you would with any provider.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
