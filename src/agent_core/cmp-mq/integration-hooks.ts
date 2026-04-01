import {
  type CmpAgentNeighborhood,
  type CmpIcmaPublishEnvelope,
  type CmpMqChannelKind,
  type CmpNeighborhoodDirection,
  type CmpSubscriptionRequest,
  validateCmpIcmaPublishEnvelope,
} from "./cmp-mq-types.js";
import { assertNoSkippingNeighborhoodBroadcast } from "./neighborhood-topology.js";
import { assertCmpSubscriptionAllowed } from "./subscription-guards.js";

function directionToChannel(direction: CmpNeighborhoodDirection): CmpMqChannelKind {
  switch (direction) {
    case "parent":
      return "to_parent";
    case "peer":
      return "peer";
    case "child":
      return "to_children";
  }
}

export function createCmpSubscriptionRequestsForEnvelope(params: {
  envelope: CmpIcmaPublishEnvelope;
}): CmpSubscriptionRequest[] {
  validateCmpIcmaPublishEnvelope(params.envelope);
  const channel = directionToChannel(params.envelope.direction);

  return params.envelope.targetAgentIds.map((targetAgentId) => ({
    requestId: `${params.envelope.envelopeId}:${targetAgentId}:subscription`,
    projectId: params.envelope.projectId,
    publisherAgentId: params.envelope.sourceAgentId,
    subscriberAgentId: targetAgentId,
    relation: params.envelope.direction,
    channel,
    createdAt: params.envelope.createdAt,
    metadata: {
      granularityLabel: params.envelope.granularityLabel,
      payloadRef: params.envelope.payloadRef,
      ...(params.envelope.metadata ?? {}),
    },
  }));
}

export function assertCmpValidatedNeighborhoodPublishPlan(params: {
  neighborhood: CmpAgentNeighborhood;
  envelope: CmpIcmaPublishEnvelope;
  knownAncestorIds?: readonly string[];
  parentPeerIds?: readonly string[];
}): CmpSubscriptionRequest[] {
  assertNoSkippingNeighborhoodBroadcast({
    envelope: params.envelope,
    knownAncestorIds: params.knownAncestorIds,
    parentPeerIds: params.parentPeerIds,
  });

  const requests = createCmpSubscriptionRequestsForEnvelope({
    envelope: params.envelope,
  });

  for (const request of requests) {
    assertCmpSubscriptionAllowed({
      neighborhood: params.neighborhood,
      request,
      knownAncestorIds: params.knownAncestorIds,
      parentPeerIds: params.parentPeerIds,
    });
  }

  return requests;
}
