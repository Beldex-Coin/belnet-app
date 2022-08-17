#!/bin/bash
flutter format .
cd belnet_lib/android && gradle spotlessApply
