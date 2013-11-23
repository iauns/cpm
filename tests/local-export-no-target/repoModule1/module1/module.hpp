#ifndef MODULE1_H
#define MODULE1_H

// Notice we are including another module in our public interface file:
// This module is exported so it is allowed.
#include "e1m1/module.hpp"

#include <string>

namespace CPM_MODULE1_NS {

std::string module1Function(const CPM_E1M1_GOOFY_NS::E1M1ExportedStruct& myStruct);

} // namespace CPM_MODULE1_NS 

#endif

