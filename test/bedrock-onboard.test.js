// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, it, expect } from "vitest";

import {
  BEDROCK_MODEL_OPTIONS,
  DEFAULT_BEDROCK_MODEL,
  DEFAULT_ROUTE_PROFILE,
  INFERENCE_ROUTE_URL,
  MANAGED_PROVIDER_ID,
  getOpenClawPrimaryModel,
  getProviderSelectionConfig,
} from "../bin/lib/inference-config";

describe("bedrock provider integration", () => {
  describe("inference-config", () => {
    it("maps bedrock to the sandbox inference route and default model", () => {
      const config = getProviderSelectionConfig("bedrock");
      expect(config).not.toBeNull();
      expect(config.provider).toBe("bedrock");
      expect(config.providerLabel).toBe("AWS Bedrock");
      expect(config.endpointUrl).toBe(INFERENCE_ROUTE_URL);
      expect(config.model).toBe(DEFAULT_BEDROCK_MODEL);
      expect(config.profile).toBe(DEFAULT_ROUTE_PROFILE);
      expect(config.credentialEnv).toBe("AWS_BEARER_TOKEN_BEDROCK");
    });

    it("allows overriding the bedrock model", () => {
      const config = getProviderSelectionConfig("bedrock", "us.amazon.nova-pro-v1:0");
      expect(config.model).toBe("us.amazon.nova-pro-v1:0");
    });

    it("builds a qualified OpenClaw primary model for bedrock", () => {
      expect(getOpenClawPrimaryModel("bedrock")).toBe(
        `${MANAGED_PROVIDER_ID}/${DEFAULT_BEDROCK_MODEL}`
      );
    });

    it("builds a qualified OpenClaw primary model with explicit bedrock model", () => {
      expect(getOpenClawPrimaryModel("bedrock", "us.meta.llama3-3-70b-instruct-v1:0")).toBe(
        `${MANAGED_PROVIDER_ID}/us.meta.llama3-3-70b-instruct-v1:0`
      );
    });

    it("exposes a non-empty BEDROCK_MODEL_OPTIONS fallback list", () => {
      expect(BEDROCK_MODEL_OPTIONS.length).toBeGreaterThan(0);
      for (const option of BEDROCK_MODEL_OPTIONS) {
        expect(option.id).toBeTruthy();
        expect(option.label).toBeTruthy();
      }
    });

    it("includes Claude Sonnet as the default bedrock model", () => {
      expect(DEFAULT_BEDROCK_MODEL).toMatch(/anthropic.*claude/i);
    });
  });

  describe("REMOTE_PROVIDER_CONFIG integration", () => {
    // These tests verify the onboard.js config structure without
    // requiring the full onboard flow (which needs Docker/OpenShell).
    // We load the config constants directly.

    it("bedrock config has the required REMOTE_PROVIDER_CONFIG fields", () => {
      // Re-read the source to check REMOTE_PROVIDER_CONFIG.bedrock
      // without requiring the full module (which has Docker dependencies).
      const fs = require("fs");
      const path = require("path");
      const source = fs.readFileSync(
        path.join(__dirname, "..", "bin", "lib", "onboard.js"),
        "utf-8"
      );
      expect(source).toContain('bedrock:');
      expect(source).toContain('providerName: "bedrock"');
      expect(source).toContain('providerType: "openai"');
      expect(source).toContain('credentialEnv: "AWS_BEARER_TOKEN_BEDROCK"');
      expect(source).toContain("requiresProxy: false");
      expect(source).toContain('modelMode: "catalog"');
    });

    it("bedrock is listed in REMOTE_MODEL_OPTIONS as a fallback", () => {
      const fs = require("fs");
      const path = require("path");
      const source = fs.readFileSync(
        path.join(__dirname, "..", "bin", "lib", "onboard.js"),
        "utf-8"
      );
      expect(source).toMatch(/REMOTE_MODEL_OPTIONS\s*=\s*\{[\s\S]*bedrock:\s*\[/);
    });

    it("bedrock is in the valid non-interactive provider set", () => {
      const fs = require("fs");
      const path = require("path");
      const source = fs.readFileSync(
        path.join(__dirname, "..", "bin", "lib", "onboard.js"),
        "utf-8"
      );
      expect(source).toMatch(/validProviders.*"bedrock"/);
    });

    it("setupInference includes bedrock in the unified provider condition", () => {
      const fs = require("fs");
      const path = require("path");
      const source = fs.readFileSync(
        path.join(__dirname, "..", "bin", "lib", "onboard.js"),
        "utf-8"
      );
      expect(source).toMatch(
        /provider === "bedrock"\)[\s\S]*?upsertProvider/
      );
    });

    it("bedrock menu option exists in setupNim", () => {
      const fs = require("fs");
      const path = require("path");
      const source = fs.readFileSync(
        path.join(__dirname, "..", "bin", "lib", "onboard.js"),
        "utf-8"
      );
      expect(source).toContain('key: "bedrock"');
      expect(source).toContain("AWS Bedrock");
    });
  });

  describe("litellm proxy script", () => {
    it("scripts/litellm-proxy.sh exists and is executable", () => {
      const fs = require("fs");
      const path = require("path");
      const script = path.join(__dirname, "..", "scripts", "litellm-proxy.sh");
      expect(fs.existsSync(script)).toBe(true);
      const stat = fs.statSync(script);
      expect(stat.mode & 0o111).toBeGreaterThan(0);
    });

    it("litellm-proxy.sh has start/stop/status commands", () => {
      const fs = require("fs");
      const path = require("path");
      const content = fs.readFileSync(
        path.join(__dirname, "..", "scripts", "litellm-proxy.sh"),
        "utf-8"
      );
      expect(content).toContain("do_start");
      expect(content).toContain("do_stop");
      expect(content).toContain("do_status");
      expect(content).toContain("litellm");
      expect(content).toContain("config.yaml");
    });

    it("litellm-proxy.sh generates bedrock config with api_key", () => {
      const fs = require("fs");
      const path = require("path");
      const content = fs.readFileSync(
        path.join(__dirname, "..", "scripts", "litellm-proxy.sh"),
        "utf-8"
      );
      expect(content).toContain("AWS_BEARER_TOKEN_BEDROCK");
      expect(content).toContain('model: "bedrock/*"');
    });
  });
});
