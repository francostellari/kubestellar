#!/usr/bin/env bash

kubectl rollout status deployment kcp --timeout=600s
