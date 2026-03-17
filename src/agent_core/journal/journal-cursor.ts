import type { JournalCursor } from "../types/kernel-session.js";

const CURSOR_PREFIX = "journal";

export interface DecodedJournalCursor {
  segmentId: number;
  offset: number;
}

export function encodeJournalCursor(
  segmentId: number,
  offset: number
): JournalCursor {
  if (!Number.isInteger(segmentId) || segmentId < 0) {
    throw new RangeError(`Invalid segmentId ${segmentId}.`);
  }
  if (!Number.isInteger(offset) || offset < 0) {
    throw new RangeError(`Invalid offset ${offset}.`);
  }

  return `${CURSOR_PREFIX}:${segmentId}:${offset}`;
}

export function decodeJournalCursor(cursor: JournalCursor): DecodedJournalCursor {
  const [prefix, segmentIdText, offsetText] = cursor.split(":");
  if (prefix !== CURSOR_PREFIX || segmentIdText === undefined || offsetText === undefined) {
    throw new Error(`Invalid journal cursor ${cursor}.`);
  }

  const segmentId = Number.parseInt(segmentIdText, 10);
  const offset = Number.parseInt(offsetText, 10);
  if (!Number.isInteger(segmentId) || segmentId < 0) {
    throw new Error(`Invalid journal cursor segment in ${cursor}.`);
  }
  if (!Number.isInteger(offset) || offset < 0) {
    throw new Error(`Invalid journal cursor offset in ${cursor}.`);
  }

  return {
    segmentId,
    offset
  };
}
