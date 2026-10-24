#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <chrono>
#include <cstdint>
#include <condition_variable>
#include <cstring>
#include <fstream>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "wic_decode_plugin.h"

namespace wic_decode {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(WicDecodePlugin, NotImplementedForUnknownMethod) {
  WicDecodePlugin plugin;
  bool not_implemented = false;
  plugin.HandleMethodCall(
      MethodCall("unknownMethod", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          nullptr, nullptr,
          [&not_implemented]() { not_implemented = true; }));
  EXPECT_TRUE(not_implemented);
}

TEST(WicDecodePlugin, DecodeToFileRequiresArguments) {
  WicDecodePlugin plugin;
  std::string error_code;
  std::mutex m;
  std::condition_variable cv;
  bool done = false;
  plugin.HandleMethodCall(
      MethodCall("decodeToFile", std::make_unique<EncodableValue>(EncodableMap{})),
      std::make_unique<MethodResultFunctions<>>(
          [&done, &cv](const EncodableValue*) {
            done = true;
            cv.notify_one();
          },
          [&error_code, &done, &cv](const std::string& code, const std::string&,
                                    const EncodableValue*) {
            error_code = code;
            done = true;
            cv.notify_one();
          },
          [&done, &cv]() {
            done = true;
            cv.notify_one();
          }));
  std::unique_lock<std::mutex> lock(m);
  cv.wait_for(lock, std::chrono::seconds(5), [&done]() { return done; });
  EXPECT_TRUE(done);
  EXPECT_EQ(error_code, "invalid_arguments");
}

TEST(WicDecodePlugin, DecodeToFileRequiresBothDimensions) {
  WicDecodePlugin plugin;
  EncodableMap args;
  args[EncodableValue(std::string("srcImage"))] = EncodableValue(std::string("src"));
  args[EncodableValue(std::string("destFile"))] = EncodableValue(std::string("dest"));
  args[EncodableValue(std::string("outWidth"))] = EncodableValue(int32_t(2));
  std::string error_code;
  std::mutex m;
  std::condition_variable cv;
  bool done = false;
  plugin.HandleMethodCall(
      MethodCall("decodeToFile", std::make_unique<EncodableValue>(args)),
      std::make_unique<MethodResultFunctions<>>(
          [&done, &cv](const EncodableValue*) {
            done = true;
            cv.notify_one();
          },
          [&error_code, &done, &cv](const std::string& code, const std::string&,
                                    const EncodableValue*) {
            error_code = code;
            done = true;
            cv.notify_one();
          },
          [&done, &cv]() {
            done = true;
            cv.notify_one();
          }));
  std::unique_lock<std::mutex> lock(m);
  cv.wait_for(lock, std::chrono::seconds(5), [&done]() { return done; });
  EXPECT_TRUE(done);
  EXPECT_EQ(error_code, "invalid_arguments");
}

TEST(WicDecodePlugin, DecodeToFileWritesRawPixels) {
  char tempPath[MAX_PATH];
  GetTempPathA(MAX_PATH, tempPath);
  std::string src = std::string(tempPath) + "wic_test_src.bmp";
  std::string dest = std::string(tempPath) + "wic_test_dest.raw";

  // Build a minimal 1x1 24bpp BMP.
  std::vector<unsigned char> bmp(58, 0);
  bmp[0] = 'B';
  bmp[1] = 'M';
  uint32_t fileSize = 58;
  std::memcpy(&bmp[2], &fileSize, 4);
  uint32_t offset = 54;
  std::memcpy(&bmp[10], &offset, 4);
  uint32_t dibSize = 40;
  std::memcpy(&bmp[14], &dibSize, 4);
  int32_t w = 1, h = 1;
  std::memcpy(&bmp[18], &w, 4);
  std::memcpy(&bmp[22], &h, 4);
  uint16_t planes = 1;
  std::memcpy(&bmp[26], &planes, 2);
  uint16_t bpp = 24;
  std::memcpy(&bmp[28], &bpp, 2);
  uint32_t imgSize = 4;
  std::memcpy(&bmp[34], &imgSize, 4);
  bmp[54] = 0x00;
  bmp[55] = 0x00;
  bmp[56] = 0xFF;
  bmp[57] = 0x00;
  {
    std::ofstream f(src, std::ios::binary | std::ios::trunc);
    f.write(reinterpret_cast<const char*>(bmp.data()), bmp.size());
  }

  WicDecodePlugin plugin;
  EncodableMap args;
  args[EncodableValue(std::string("srcImage"))] = EncodableValue(src);
  args[EncodableValue(std::string("destFile"))] = EncodableValue(dest);
  std::string error_code, error_message;
  std::mutex m;
  std::condition_variable cv;
  bool done = false;
  bool ok = false;
  plugin.HandleMethodCall(
      MethodCall("decodeToFile", std::make_unique<EncodableValue>(args)),
      std::make_unique<MethodResultFunctions<>>(
          [&ok, &done, &cv](const EncodableValue*) {
            ok = true;
            done = true;
            cv.notify_one();
          },
          [&error_code, &error_message, &done, &cv](const std::string& code,
                                                   const std::string& msg,
                                                   const EncodableValue*) {
            error_code = code;
            error_message = msg;
            done = true;
            cv.notify_one();
          },
          [&done, &cv]() {
            done = true;
            cv.notify_one();
          }));
  std::unique_lock<std::mutex> lock(m);
  cv.wait_for(lock, std::chrono::seconds(10), [&done]() { return done; });
  EXPECT_TRUE(done);
  if (!ok) {
    FAIL() << "decode failed: " << error_code << " " << error_message;
  }
  std::ifstream check(dest, std::ios::binary | std::ios::ate);
  EXPECT_TRUE(check.good());
  EXPECT_EQ(static_cast<size_t>(check.tellg()), 4u);

  std::remove(src.c_str());
  std::remove(dest.c_str());
}

}  // namespace test
}  // namespace wic_decode
