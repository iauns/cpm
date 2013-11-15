#ifndef MAIN_CENTRAL_H
#define MAIN_CENTRAL_H

// Notice we are including another module in our public interface file:
// This module is exported so it is allowed.
#include "central_exp/module.hpp"

#include <string>

namespace CPM_CENTRAL_NS {

std::string centralFunction(CPM_CENTRAL_EXP_NS::CentralSubExportedStruct& myStruct);
std::string centralFunction2(int num);

} // namespace CPM_CENTRAL_NS 

#endif

