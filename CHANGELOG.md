## 0.2.1
* Only create cluster and load images on deploy.
  - Uses the `deploy` hook instead of `before_deploy`, which is called during `kuby resources` used to simulate a deploy so tag info is populated correctly.

## 0.2.0
* Allow configuring Kubernetes version.
* Fix storage class name
  - Used to be "default" and is now "standard."

## 0.1.0
* Birthday!
