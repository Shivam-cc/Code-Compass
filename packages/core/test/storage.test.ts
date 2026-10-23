import { expect, test } from "bun:test";
import { homedir } from "node:os";
import { join } from "node:path";
import { storageDirectory } from "../src/storage";

test("XDG locations win on every platform", () => {
  const env = { XDG_CONFIG_HOME: "/xdg/config", XDG_CACHE_HOME: "/xdg/cache", APPDATA: "/roaming" };
  for (const platform of ["linux", "darwin", "win32"] as const) {
    expect(storageDirectory("config", env, platform)).toBe(join("/xdg/config", "codecompass"));
    expect(storageDirectory("cache", env, platform)).toBe(join("/xdg/cache", "codecompass"));
  }
});

test("Windows uses APPDATA for config and LOCALAPPDATA for cache", () => {
  const env = { APPDATA: "/roaming", LOCALAPPDATA: "/local" };
  expect(storageDirectory("config", env, "win32")).toBe(join("/roaming", "codecompass"));
  expect(storageDirectory("cache", env, "win32")).toBe(join("/local", "codecompass"));
});

test("Windows falls back to the profile AppData folders when the variables are unset", () => {
  expect(storageDirectory("config", {}, "win32")).toBe(
    join(homedir(), "AppData", "Roaming", "codecompass"),
  );
  expect(storageDirectory("cache", {}, "win32")).toBe(
    join(homedir(), "AppData", "Local", "codecompass"),
  );
});

test("macOS and Linux keep the XDG defaults and ignore Windows variables", () => {
  const env = { APPDATA: "/roaming", LOCALAPPDATA: "/local" };
  for (const platform of ["linux", "darwin"] as const) {
    expect(storageDirectory("config", env, platform)).toBe(join(homedir(), ".config", "codecompass"));
    expect(storageDirectory("cache", env, platform)).toBe(join(homedir(), ".cache", "codecompass"));
  }
});
