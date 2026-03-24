import {
  type CmpAgentNeighborhood,
  type CmpMqChannelKind,
  type CmpSubscriptionRelation,
  type CmpSubscriptionRequest,
  validateCmpAgentNeighborhood,
  validateCmpSubscriptionRequest,
} from "./cmp-mq-types.js";

export const CMP_ALLOWED_SUBSCRIPTION_CHANNELS: Record<
  CmpSubscriptionRelation,
  readonly CmpMqChannelKind[]
> = {
  parent: ["to_parent", "promotion", "critical_escalation"],
  peer: ["peer"],
  child: ["to_children"],
};

export function resolveCmpSubscriptionRelation(params: {
  neighborhood: CmpAgentNeighborhood;
  subscriberAgentId: string;
}): CmpSubscriptionRelation | undefined {
  validateCmpAgentNeighborhood(params.neighborhood);
  const subscriberAgentId = params.subscriberAgentId.trim();
  if (params.neighborhood.parentAgentId === subscriberAgentId) {
    return "parent";
  }
  if (params.neighborhood.peerAgentIds.includes(subscriberAgentId)) {
    return "peer";
  }
  if (params.neighborhood.childAgentIds.includes(subscriberAgentId)) {
    return "child";
  }
  return undefined;
}

export function canCmpSubscribeToChannel(params: {
  relation: CmpSubscriptionRelation;
  channel: CmpMqChannelKind;
}): boolean {
  return CMP_ALLOWED_SUBSCRIPTION_CHANNELS[params.relation].includes(params.channel);
}

export function assertCmpSubscriptionAllowed(params: {
  neighborhood: CmpAgentNeighborhood;
  request: CmpSubscriptionRequest;
  knownAncestorIds?: readonly string[];
  parentPeerIds?: readonly string[];
}): void {
  validateCmpAgentNeighborhood(params.neighborhood);
  validateCmpSubscriptionRequest(params.request);

  if (params.request.publisherAgentId !== params.neighborhood.agentId) {
    throw new Error(
      `CMP subscription publisher ${params.request.publisherAgentId} does not match neighborhood owner ${params.neighborhood.agentId}.`,
    );
  }

  const relation = resolveCmpSubscriptionRelation({
    neighborhood: params.neighborhood,
    subscriberAgentId: params.request.subscriberAgentId,
  });
  if (!relation) {
    const knownAncestors = new Set(params.knownAncestorIds ?? []);
    if (knownAncestors.has(params.request.subscriberAgentId)) {
      throw new Error(
        `CMP subscription cannot skip upward to ancestor ${params.request.subscriberAgentId}.`,
      );
    }
    const parentPeers = new Set(params.parentPeerIds ?? []);
    if (parentPeers.has(params.request.subscriberAgentId)) {
      throw new Error(
        `CMP subscription cannot target parent-peer ${params.request.subscriberAgentId} without parent mediation.`,
      );
    }
    throw new Error(
      `CMP subscription target ${params.request.subscriberAgentId} is outside the local neighborhood.`,
    );
  }

  if (relation !== params.request.relation) {
    throw new Error(
      `CMP subscription relation mismatch: request says ${params.request.relation}, resolved ${relation}.`,
    );
  }

  if (!canCmpSubscribeToChannel({
    relation,
    channel: params.request.channel,
  })) {
    throw new Error(
      `CMP subscription relation ${relation} cannot subscribe to channel ${params.request.channel}.`,
    );
  }
}

