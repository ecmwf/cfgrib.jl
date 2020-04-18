#!/usr/bin/env bash

GIT_DIR=$(git rev-parse --git-dir)

echo "Installing hooks..."

ln -s "../../test/scripts/pre-push.jl" "$GIT_DIR/hooks/pre-push"

ln -s "../../test/scripts/pre-commit.jl" "$GIT_DIR/hooks/pre-commit"

echo "Done!"
