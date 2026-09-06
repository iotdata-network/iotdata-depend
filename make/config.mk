# config.mk — iotdata-depend include paths (the vendored driver submodules).
#
# Include AFTER iotdata-common/make/config.mk, which defines IOTDATA_SRC_DEPEND:
#   include $(IOTDATA_SRC)/iotdata-common/make/config.mk
#   include $(IOTDATA_SRC)/iotdata-depend/make/config.mk
#
# Only submodules with a public include/ dir are listed.

IOTDATA_SRC_DEPEND_E22XXXTXX ?= $(IOTDATA_SRC_DEPEND)/e22900t22/include
IOTDATA_SRC_DEPEND_RAK3272   ?= $(IOTDATA_SRC_DEPEND)/rak3272/include
IOTDATA_SRC_DEPEND_BLACKBOX  ?= $(IOTDATA_SRC_DEPEND)/blackbox/include
