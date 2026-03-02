"""Model router — deterministic model selection per panel and persona.

Routes panels and personas to appropriate models based on task criticality
tiers or explicit per-panel/persona overrides in project.yaml.

Configuration in project.yaml:

    governance:
      models:
        default: "auto"          # or a specific model ID
        tiers:
          high: "opus"           # High-stakes tasks
          standard: "sonnet"     # Balanced cost/quality
          low: "haiku"           # Cost-effective
        panels:
          security-review: "opus"
          documentation-review: "haiku"
        personas:
          tester: "opus"
          coder: "sonnet"

When models.default is "auto" or the models section is omitted, the
router uses criticality tiers to select models deterministically.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class CriticalityTier(str, Enum):
    """Task criticality tiers for model routing."""
    HIGH = "high"
    STANDARD = "standard"
    LOW = "low"


# Default criticality mappings
_PANEL_CRITICALITY: dict[str, CriticalityTier] = {
    "security-review": CriticalityTier.HIGH,
    "threat-modeling": CriticalityTier.HIGH,
    "code-review": CriticalityTier.STANDARD,
    "data-governance-review": CriticalityTier.STANDARD,
    "documentation-review": CriticalityTier.LOW,
    "cost-analysis": CriticalityTier.LOW,
}

_PERSONA_CRITICALITY: dict[str, CriticalityTier] = {
    "tester": CriticalityTier.HIGH,
    "coder": CriticalityTier.STANDARD,
    "code-manager": CriticalityTier.STANDARD,
    "devops-engineer": CriticalityTier.STANDARD,
    "iac-engineer": CriticalityTier.STANDARD,
    "project-manager": CriticalityTier.STANDARD,
}

# Default tier-to-model mapping
_DEFAULT_TIER_MODELS: dict[CriticalityTier, str] = {
    CriticalityTier.HIGH: "opus",
    CriticalityTier.STANDARD: "sonnet",
    CriticalityTier.LOW: "haiku",
}


@dataclass(frozen=True)
class ModelConfig:
    """Parsed model configuration from project.yaml."""

    default: str = "auto"
    tier_models: dict[str, str] = field(default_factory=lambda: {
        "high": "opus",
        "standard": "sonnet",
        "low": "haiku",
    })
    panel_overrides: dict[str, str] = field(default_factory=dict)
    persona_overrides: dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: dict | None) -> ModelConfig:
        """Parse from the governance.models section of project.yaml."""
        if not data:
            return cls()

        return cls(
            default=data.get("default", "auto"),
            tier_models={
                "high": data.get("tiers", {}).get("high", "opus"),
                "standard": data.get("tiers", {}).get("standard", "sonnet"),
                "low": data.get("tiers", {}).get("low", "haiku"),
            },
            panel_overrides=data.get("panels", {}),
            persona_overrides=data.get("personas", {}),
        )


class ModelRouter:
    """Deterministic model router for panels and personas.

    The engine makes the routing decision. The LLM receives an instruction
    to use a specific model — it does not choose its own.
    """

    def __init__(self, config: ModelConfig | None = None):
        self._config = config or ModelConfig()

    @property
    def config(self) -> ModelConfig:
        return self._config

    def resolve_panel_model(self, panel_name: str) -> str:
        """Resolve the model to use for a given panel.

        Priority:
        1. Explicit panel override in config
        2. Explicit default model (if not "auto")
        3. Auto-route by criticality tier
        """
        # Check explicit panel override
        if panel_name in self._config.panel_overrides:
            return self._config.panel_overrides[panel_name]

        # Check explicit default
        if self._config.default != "auto":
            return self._config.default

        # Auto-route by criticality
        tier = _PANEL_CRITICALITY.get(panel_name, CriticalityTier.STANDARD)
        return self._resolve_tier_model(tier)

    def resolve_persona_model(self, persona_name: str) -> str:
        """Resolve the model to use for a given persona.

        Priority:
        1. Explicit persona override in config
        2. Explicit default model (if not "auto")
        3. Auto-route by criticality tier
        """
        # Check explicit persona override
        if persona_name in self._config.persona_overrides:
            return self._config.persona_overrides[persona_name]

        # Check explicit default
        if self._config.default != "auto":
            return self._config.default

        # Auto-route by criticality
        tier = _PERSONA_CRITICALITY.get(persona_name, CriticalityTier.STANDARD)
        return self._resolve_tier_model(tier)

    def resolve_task_model(self, panel_name: str | None = None, persona_name: str | None = None) -> str:
        """Resolve model for a task that may have both panel and persona context.

        If both are provided, panel takes priority (the panel drives the work).
        """
        if panel_name:
            return self.resolve_panel_model(panel_name)
        if persona_name:
            return self.resolve_persona_model(persona_name)
        # Fallback
        if self._config.default != "auto":
            return self._config.default
        return self._resolve_tier_model(CriticalityTier.STANDARD)

    def get_routing_summary(self) -> dict:
        """Return a summary of model routing for all known panels and personas."""
        panels = {}
        for panel in _PANEL_CRITICALITY:
            panels[panel] = {
                "model": self.resolve_panel_model(panel),
                "criticality": _PANEL_CRITICALITY[panel].value,
                "override": panel in self._config.panel_overrides,
            }

        personas = {}
        for persona in _PERSONA_CRITICALITY:
            personas[persona] = {
                "model": self.resolve_persona_model(persona),
                "criticality": _PERSONA_CRITICALITY[persona].value,
                "override": persona in self._config.persona_overrides,
            }

        return {
            "default": self._config.default,
            "tier_models": dict(self._config.tier_models),
            "panels": panels,
            "personas": personas,
        }

    def _resolve_tier_model(self, tier: CriticalityTier) -> str:
        """Resolve a tier to a model using config or defaults."""
        return self._config.tier_models.get(
            tier.value,
            _DEFAULT_TIER_MODELS.get(tier, "sonnet"),
        )
