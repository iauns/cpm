#ifndef MODULE2_H
#define MODULE2_H

#include <string>
#include "central/module.hpp"

namespace CPM_MYMODULE2_NS {

std::string module2Function(int num, int num2);
std::string module2CentralCall(CPM_CENTRAL_EXP_NS::CentralExportedClass& c);

} // namespace CPM_MYMODULE2_NS 

#endif

