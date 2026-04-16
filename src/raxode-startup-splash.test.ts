import assert from "node:assert/strict";
import test from "node:test";

import { raxodeStartupSplashTestUtils } from "./raxode-startup-splash.js";

test("typing frame grows with a moving block cursor", () => {
  const emptyFrame = raxodeStartupSplashTestUtils.buildTypingFrame(0)[0] ?? "";
  const helloFrame = raxodeStartupSplashTestUtils.buildTypingFrame(5)[0] ?? "";
  const fullFrame = raxodeStartupSplashTestUtils.buildTypingFrame("Hello, AI World!".length)[0] ?? "";

  assert.equal(emptyFrame.startsWith(">> █"), true);
  assert.equal(helloFrame.startsWith(">> Hello█"), true);
  assert.equal(fullFrame.startsWith(">> Hello, AI World!█"), true);
  assert.equal(emptyFrame.length, helloFrame.length);
  assert.equal(helloFrame.length, fullFrame.length);
});

test("Praxis reveal and erase frames progress left-to-right and top-to-bottom", () => {
  const reveal = raxodeStartupSplashTestUtils.buildPraxisRevealFrame(1, 4);
  assert.equal(reveal[0]?.length > 0, true);
  assert.equal(reveal[1], "██╔═");
  assert.equal(reveal[2], "");

  const erased = raxodeStartupSplashTestUtils.buildPraxisEraseFrame(0, 4);
  assert.equal(erased[0], "████╗");
  assert.equal(erased[1], "██╔════██╗                            ██╗");
});
