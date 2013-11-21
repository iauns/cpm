#ifndef MODULE3_H
#define MODULE3_H

#include <string>
#include "central_exp/module.hpp"

namespace CPM_MODULE3_NS {

std::string module3Function(const std::string& in, int num,
                            CPM_CENTRAL_EXP_NS::CentralExportedClass& c);

} // namespace CPM_MODULE3_NS 

#endif

