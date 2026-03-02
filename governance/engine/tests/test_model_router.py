"""Tests for model_router — deterministic model selection per panel and persona."""

import pytest

from governance.engine.orchestrator.model_router import (
    CriticalityTier,
    ModelConfig,
    ModelRouter,
)


class TestModelConfig:
    """Tests for ModelConfig parsing."""

    def test_default_config(self):
        config = ModelConfig()
        assert config.default == "auto"
        assert config.tier_models["high"] == "opus"
        assert config.tier_models["standard"] == "sonnet"
        assert config.tier_models["low"] == "haiku"
        assert config.panel_overrides == {}
        assert config.persona_overrides == {}

    def test_from_dict_none(self):
        config = ModelConfig.from_dict(None)
        assert config.default == "auto"

    def test_from_dict_empty(self):
        config = ModelConfig.from_dict({})
        assert config.default == "auto"

    def test_from_dict_with_default(self):
        config = ModelConfig.from_dict({"default": "sonnet"})
        assert config.default == "sonnet"

    def test_from_dict_with_tiers(self):
        config = ModelConfig.from_dict({
            "tiers": {"high": "gpt-4", "standard": "gpt-3.5", "low": "gpt-3.5"}
        })
        assert config.tier_models["high"] == "gpt-4"
        assert config.tier_models["standard"] == "gpt-3.5"

    def test_from_dict_with_overrides(self):
        config = ModelConfig.from_dict({
            "panels": {"security-review": "opus"},
            "personas": {"tester": "opus"},
        })
        assert config.panel_overrides["security-review"] == "opus"
        assert config.persona_overrides["tester"] == "opus"

    def test_from_dict_full(self):
        config = ModelConfig.from_dict({
            "default": "auto",
            "tiers": {"high": "opus", "standard": "sonnet", "low": "haiku"},
            "panels": {"security-review": "opus", "documentation-review": "haiku"},
            "personas": {"tester": "opus", "coder": "sonnet"},
        })
        assert config.default == "auto"
        assert config.tier_models["high"] == "opus"
        assert config.panel_overrides["security-review"] == "opus"
        assert config.persona_overrides["tester"] == "opus"


class TestModelRouterAutoMode:
    """Tests for auto-routing by criticality tier."""

    def test_high_criticality_panel(self):
        router = ModelRouter()
        assert router.resolve_panel_model("security-review") == "opus"
        assert router.resolve_panel_model("threat-modeling") == "opus"

    def test_standard_criticality_panel(self):
        router = ModelRouter()
        assert router.resolve_panel_model("code-review") == "sonnet"
        assert router.resolve_panel_model("data-governance-review") == "sonnet"

    def test_low_criticality_panel(self):
        router = ModelRouter()
        assert router.resolve_panel_model("documentation-review") == "haiku"
        assert router.resolve_panel_model("cost-analysis") == "haiku"

    def test_unknown_panel_gets_standard(self):
        router = ModelRouter()
        assert router.resolve_panel_model("unknown-panel") == "sonnet"

    def test_high_criticality_persona(self):
        router = ModelRouter()
        assert router.resolve_persona_model("tester") == "opus"

    def test_standard_criticality_persona(self):
        router = ModelRouter()
        assert router.resolve_persona_model("coder") == "sonnet"
        assert router.resolve_persona_model("code-manager") == "sonnet"
        assert router.resolve_persona_model("devops-engineer") == "sonnet"

    def test_unknown_persona_gets_standard(self):
        router = ModelRouter()
        assert router.resolve_persona_model("unknown-persona") == "sonnet"


class TestModelRouterExplicitDefault:
    """Tests for explicit default model (not auto)."""

    def test_explicit_default_overrides_auto_routing(self):
        config = ModelConfig(default="gpt-4o")
        router = ModelRouter(config)
        assert router.resolve_panel_model("security-review") == "gpt-4o"
        assert router.resolve_panel_model("documentation-review") == "gpt-4o"
        assert router.resolve_persona_model("tester") == "gpt-4o"

    def test_explicit_override_beats_default(self):
        config = ModelConfig(
            default="gpt-4o",
            panel_overrides={"security-review": "opus"},
        )
        router = ModelRouter(config)
        assert router.resolve_panel_model("security-review") == "opus"
        assert router.resolve_panel_model("code-review") == "gpt-4o"


class TestModelRouterOverrides:
    """Tests for per-panel and per-persona overrides."""

    def test_panel_override(self):
        config = ModelConfig(
            panel_overrides={"security-review": "gpt-4"},
        )
        router = ModelRouter(config)
        assert router.resolve_panel_model("security-review") == "gpt-4"
        # Non-overridden panel still auto-routes
        assert router.resolve_panel_model("code-review") == "sonnet"

    def test_persona_override(self):
        config = ModelConfig(
            persona_overrides={"coder": "opus"},
        )
        router = ModelRouter(config)
        assert router.resolve_persona_model("coder") == "opus"
        # Non-overridden persona still auto-routes
        assert router.resolve_persona_model("tester") == "opus"

    def test_custom_tier_models(self):
        config = ModelConfig(
            tier_models={"high": "claude-4", "standard": "claude-3.5", "low": "claude-3"},
        )
        router = ModelRouter(config)
        assert router.resolve_panel_model("security-review") == "claude-4"
        assert router.resolve_panel_model("code-review") == "claude-3.5"
        assert router.resolve_panel_model("documentation-review") == "claude-3"


class TestModelRouterTaskModel:
    """Tests for resolve_task_model with combined context."""

    def test_panel_takes_priority(self):
        router = ModelRouter()
        model = router.resolve_task_model(panel_name="security-review", persona_name="coder")
        assert model == "opus"

    def test_persona_when_no_panel(self):
        router = ModelRouter()
        model = router.resolve_task_model(persona_name="tester")
        assert model == "opus"

    def test_fallback_when_neither(self):
        router = ModelRouter()
        model = router.resolve_task_model()
        assert model == "sonnet"

    def test_fallback_with_explicit_default(self):
        config = ModelConfig(default="gpt-4o")
        router = ModelRouter(config)
        model = router.resolve_task_model()
        assert model == "gpt-4o"


class TestModelRouterSummary:
    """Tests for routing summary."""

    def test_summary_structure(self):
        router = ModelRouter()
        summary = router.get_routing_summary()
        assert "default" in summary
        assert "tier_models" in summary
        assert "panels" in summary
        assert "personas" in summary
        assert "security-review" in summary["panels"]
        assert "tester" in summary["personas"]

    def test_summary_shows_overrides(self):
        config = ModelConfig(panel_overrides={"security-review": "gpt-4"})
        router = ModelRouter(config)
        summary = router.get_routing_summary()
        assert summary["panels"]["security-review"]["override"] is True
        assert summary["panels"]["code-review"]["override"] is False
