## 0.2.4
* Guard against `nil`s when fetching loaded images.

## 0.2.3
* Remove mistakenly added `require 'pry-byebug'` 🤦

## 0.2.2
* Add missing 'require'.

## 0.2.1
* Only create cluster and load images on deploy.
  - Uses the `deploy` hook instead of `before_deploy`, which is called during `kuby resources` used to simulate a deploy so tag info is populated correctly.

## 0.2.0
* Allow configuring Kubernetes version.
* Fix storage class name
  - Used to be "default" and is now "standard."

## 0.1.0
* Birthday!
