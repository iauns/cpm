#ifndef MODULE2_H
#define MODULE2_H

#include <string>

// Forward declaration of type in central module.
namespace CPM_CENTRAL_NS {
  class CentralExportedClass;
} // namespace CPM_CENTRAL_NS

namespace CPM_MYMODULE2_NS {

std::string module2Function(int num, int num2);
std::string module2CentralCall(CPM_CENTRAL_NS::CentralExportedClass& c);

} // namespace CPM_MYMODULE2_NS 

#endif

